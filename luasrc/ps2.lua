local ps2 = {}

function ps2.cmd(cmd_byte)
    -- wait for controller input buffer to become clear
    while (ps2.status() & 2) > 0 do end

    kx.outb(0x64, cmd_byte)
end

function ps2.status()
    return kx.inb(0x64)
end

function ps2.hasrdata()
  return (ps2.status() & 0x1) > 0
end

function ps2.rdata()
    return kx.inb(0x60)
end

function ps2.wdata(data_byte)
    -- wait for controller input buffer to become clear
    while (ps2.status() & 2) > 0 do end

    kx.outb(0x60, data_byte)
end

function ps2.wport1(cmd_byte)
  while true do
    while (ps2.status() & 2) > 0 do end
    kx.outb(0x60, cmd_byte)
    while not ps2.hasrdata() do end
    local ret = ps2.rdata()
    if ret == 0xfa then return end
  end
end

function ps2.wport2(cmd_byte)
  while true do
    -- => write next byte to port 2
    ps2.cmd(0xd4)
    while (ps2.status() & 2) > 0 do end
    kx.outb(0x60, cmd_byte)
    while not ps2.hasrdata() do end
    local ret = ps2.rdata()
    if ret == 0xfa then return end
  end
end


function ps2.init()
  -- TODO: determine if ps/2 controller even exists!
  -- shouldn't do all this if it doesn't...
  

  -- !!!!!!!!!!!!!!!!!
  -- NOTE: need to start waiting for data ready!!!!!!!!
  -- !!!!!!!!!!!!!!!!!

  -- disable both ports
  ps2.cmd(0xad)
  ps2.cmd(0xa7)

  -- flush controller out buffer
  while ps2.hasrdata() do ps2.rdata() end

  -- disable both port interrupts & translation
  ps2.cmd(0x20)
  local ccb = ps2.rdata()
  ccb = ccb & 0x3c
  ps2.cmd(0x60)
  ps2.wdata(ccb)

  -- controller self test
  ps2.cmd(0xaa)
  while not ps2.hasrdata() do end
  local post_reply = ps2.rdata()

  if post_reply == 0x55 then
    dprint("  PS/2 self test -> OK (0x55)\n")
  else
    dprint(string.format("  PS/2 self test -> ?? (0x%x)\n", post_reply))
    dprint("  Giving up.\n")
    return false
  end

  -- is this a 2-port controller?
  ps2.cmd(0xa8)
  -- ..shouldn't have a return value..
  -- does ccb have 32 (5th bit) clear?
  ps2.cmd(0x20)
  while not ps2.hasrdata() do end
  local ccb = ps2.rdata()
  if ccb & 32 == 0 then
    ps2.twoports = true
  else
    ps2.twoports = false
  end
  dprint(string.format("  PS/2 two ports? %s\n", ps2.twoports))
  -- if we did in fact enable a second port, then disable it again now.
  if ps2.twoports then ps2.cmd(0xa7) end

  dprint("  PS/2 port tests...  Port 1: ")
  -- test port 1
  ps2.cmd(0xab)
  while not ps2.hasrdata() do end
  local p1result = ps2.rdata()
  ps2.port1ok = false
  if p1result == 0x00 then
    ps2.port1ok = true
    dprint("OK")
  elseif p1result == 0x01 then
    dprint("Clock stuck low")
  elseif p1result == 0x02 then
    dprint("Clock stuck high")
  elseif p1result == 0x03 then
    dprint("Data stuck low")
  elseif p1result == 0x04 then
    dprint("Data stuck high")
  else
    dprint(string.format("?? (0x%x)", p1result))
  end

  -- test port 2
  dprint(", Port 2: ")
  ps2.port2ok = false
  if ps2.twoports then
    ps2.cmd(0xa9)
    while not ps2.hasrdata() do end
    local p2result = ps2.rdata()
    if p2result == 0x00 then
      ps2.port2ok = true
      dprint("OK")
    elseif p2result == 0x01 then
      dprint("Clock stuck low")
    elseif p2result == 0x02 then
      dprint("Clock stuck high")
    elseif p2result == 0x03 then
      dprint("Data stuck low")
    elseif p2result == 0x04 then
      dprint("Data stuck high")
    else
      dprint(string.format("?? (0x%x)", p2result))
    end
  else
    dprint("N/A")
  end

  dprint("\n")

  -- enable ports (TODO: interrupts (ccb)!!!!!)
  
  -- just temporarily, i actually want to find just the keyboard.
  
  if ps2.port1ok then
    ps2.cmd(0xae)

    ps2.wport1(0xf5)
    ps2.wport1(0xf2)
    while not ps2.hasrdata() do end
    local d1 = ps2.rdata()
    if d1 == 0xab then
      while not ps2.hasrdata() do end
      local d2 = ps2.rdata()
      dprint(string.format("p1 id 0xab 0x%x\n", d2))
      ps2.port1id = {0xab, d2}
    else
      dprint(string.format("p1 id 0x%x\n", d1))
      ps2.port1id = {d1}
    end

    ps2.cmd(0xad)
  end

  if ps2.port2ok then
    ps2.cmd(0xa8)

    ps2.wport2(0xf5)
    ps2.wport2(0xf2)
    while not ps2.hasrdata() do end
    local d1 = ps2.rdata()
    if d1 == 0xab then
      while not ps2.hasrdata() do end
      local d2 = ps2.rdata()
      dprint(string.format("p2 id 0xab 0x%x\n", d2))
      ps2.port2id = {0xab, d2}
    else
      dprint(string.format("p2 id 0x%x\n", d1))
      ps2.port2id = {d1}
    end

    ps2.cmd(0xa7)
  end

  local scans = {
    [0x1c]="a",
    [0x32]="b",
    [0x21]="c",
    [0x23]="d",
    [0x24]="e",
    [0x2b]="f",
    [0x34]="g",
    [0x33]="h",
    [0x43]="i",
    [0x3b]="j",
    [0x42]="k",
    [0x4b]="l",
    [0x3a]="m",
    [0x31]="n",
    [0x44]="o",
    [0x4d]="p",
    [0x15]="q",
    [0x2d]="r",
    [0x1b]="s",
    [0x2c]="t",
    [0x3c]="u",
    [0x2a]="v",
    [0x1d]="w",
    [0x22]="x",
    [0x35]="y",
    [0x1a]="z"
  }

  -- !! JUST FOR TESTING !!
  -- ...why does this work?! i thought i've disabled the ps/2 ports :s
  --[[while true do
    while not ps2.hasrdata() do end
    local z = ps2.rdata()
    if z == 0xf0 then
      -- for now, ignore next
      while not ps2.hasrdata() do end
      ps2.rdata()
    else
      dprint(scans[z] or "?")

    end


  end]]--
  

  return true
end


-- hax for now
_G["ps2"] = ps2

return ps2


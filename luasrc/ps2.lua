local ps2 = {}

function ps2.cmd(cmd_byte)
    -- wait for controller input buffer to become clear
    while (ps2.status() & 2) > 0 do end

    kx.outb(0x64, cmd_byte)
end

function ps2.status()
    return kx.inb(0x64)
end

function ps2.rdata()
    return kx.inb(0x60)
end

function ps2.wdata(data_byte)
    -- wait for controller input buffer to become clear
    while (ps2.status() & 2) > 0 do end

    kx.outb(0x60, data_byte)
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
    ps2.rdata()

    -- disable both port interrupts & translation
    ps2.cmd(0x20)
    local ccb = ps2.rdata()
    ccb = ccb & 0x3c
    ps2.cmd(0x60)
    ps2.wdata(ccb)

    -- controller self test

end


-- hax for now
_G["ps2"] = ps2

return ps2


local bisqit = {}

function bisqit.cpuid()
  dprint("CPUID: ")

  local oki, a, b, c, d = kx.cpuid(0)

  assert(oki == 1)

  local function toFour(x)
    local s = string.char(x & 0xff)
    s = s .. string.char((x >> 8) & 0xff)
    s = s .. string.char((x >> 16) & 0xff)
    s = s .. string.char((x >> 24) & 0xff)
    return s
  end

  bisqit.info = {}

  bisqit.info.cpuVendor = toFour(b) .. toFour(d) .. toFour(c)
  dprint(bisqit.info.cpuVendor)
  dprint(" ")

  local oki, a, b, c, d = kx.cpuid(1)
  assert(oki == 1)
  local edx_apic = (1 << 9)
  local ecx_x2apic = (1 << 21)

  if d & edx_apic > 0 then
    dprint("APIC ")
  else
    dprint("No-APIC ")
  end
  bisqit.info.apic = (d & edx_apic > 0)

  if c & ecx_x2apic > 0 then
    dprint("x2APIC ")
  else
    dprint("No-x2APIC ")
  end
  bisqit.info.x2apic = (c & ecx_x2apic > 0)

  local oki, a, b, c, d = kx.cpuid(0x16)
  if oki == 1 then
    dprint(string.format("@ %d MHz / %d MHz [%d MHz]", (a & 0xffff), (b & 0xffff), (c & 0xffff)))
    bisqit.info.cpuCurrentSpeed = (a & 0xffff)
    bisqit.info.cpuMaxSpeed = (b & 0xffff)
  else
    dprint("@ n/a MHz")
    bisqit.info.cpuCurrentSpeed = nil
    bisqit.info.cpuMaxSpeed = nil
  end

  local oki, a, b, c, d = kx.cpuid(0x80000002)
  assert(oki == 1)
  local oki, a2, b2, c2, d2 = kx.cpuid(0x80000003)
  assert(oki == 1)
  local oki, a3, b3, c3, d3 = kx.cpuid(0x80000004)
  assert(oki == 1)
  bisqit.info.cpuName = toFour(a) .. toFour(b) .. toFour(c) .. toFour(d) .. toFour(a2) .. toFour(b2) .. toFour(c2) .. toFour(d2) .. toFour(a3) .. toFour(b3) .. toFour(c3) .. toFour(d3)
  dprint("\ncpu name: " .. bisqit.info.cpuName)

  local oki, a, b, c, d = kx.cpuid(0x40000000)
  if oki == 1 then
    dprint("\nhypervisor vendor: " .. toFour(b) .. toFour(c) .. toFour(d))
    bisqit.info.hypervisor = toFour(b) .. toFour(c) .. toFour(d)
  else
    dprint("\nno hypervisor information in cpuid!")
    bisqit.info.hypervisor = nil
  end

  dprint("\n")
end

function bisqit.init()
  dprint("B.I.S.Q.I.T. cpu worrier is on the case!\n")

  -- fetch cpuid stuff & populate bisqit.info table
  bisqit.cpuid()

  assert(bisqit.info.apic and not bisqit.info.x2apic)

  local local_apic_base = 0xfee00000
  local io_apic_base = 0xfec00000
  -- e.g. ioapic2 would be 0xfec01000 (+4K)

  -- apparently local apic ids are the bios' & hardware's remit,
  -- but we *should* fix-up any non-unique ioapic ids ourselves.
  -- if they're already acceptable, though, we should leave them as-is.
  -- (all this TODO...)

  

end


-- hax
_G["bisqit"] = bisqit

return bisqit

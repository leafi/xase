-- stupid bytecode generator

return {
  new = function()
    local stx = {
      xs = {}
    }
    function stx:assign(where, what)
    end
    return stx
  end
}

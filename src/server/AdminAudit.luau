--!strict
local Audit = {}
local entries = {}
Audit.Changed = Instance.new("BindableEvent")
function Audit.record(actor: Player, command: string, ok: boolean, message: string)
    local entry = {name = actor.Name, command = string.sub(command, 1, 256), ok = ok, message = message, time = os.time()}
    table.insert(entries, entry)
    if #entries > 60 then table.remove(entries, 1) end
    Audit.Changed:Fire(entry)
end
function Audit.snapshot()
    return table.clone(entries)
end
return Audit

--!strict
-- Each service instance belongs to one server process and starts empty.
local History={}
function History.new()
    local entries: {[string]: {any}}={chat={},command={}}
    local sequence=0
    local store={}
    function store.append(entry: any)
        sequence+=1
        entry.sequence=sequence
        table.insert(entries[entry.kind],entry)
    end
    function store.page(kind: string,before: number?,limit: number): ({any},number,boolean)
        local ceiling=before or math.huge
        local items={}
        local cursor=ceiling
        local list=entries[kind]
        for i=#list,1,-1 do
            local entry=list[i]
            if entry.sequence<ceiling then
                if #items>=limit then return items,cursor,true end
                table.insert(items,entry)
                cursor=entry.sequence
            end
        end
        return items,cursor,false
    end
    return store
end
return History

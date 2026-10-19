--!strict
export type Rank = {read id: string, read name: string, read category: string, read order: number, read color: {number}, read symbol: string, read marks: number}
local definitions: {{string}} = {
    {"trainee", "훈련병", "훈련병"},
    {"private", "이병", "병"},
    {"private_first_class", "일병", "병"},
    {"corporal", "상병", "병"},
    {"sergeant", "병장", "병"},
    {"staff_sergeant", "하사", "부사관"},
    {"sergeant_first_class", "중사", "부사관"},
    {"master_sergeant", "상사", "부사관"},
    {"sergeant_major", "원사", "부사관"},
    {"warrant_officer", "준위", "준사관"},
    {"second_lieutenant", "소위", "위관"},
    {"first_lieutenant", "중위", "위관"},
    {"captain", "대위", "위관"},
    {"major", "소령", "영관"},
    {"lieutenant_colonel", "중령", "영관"},
    {"colonel", "대령", "영관"},
    {"brigadier_general", "준장", "장관"},
    {"major_general", "소장", "장관"},
    {"lieutenant_general", "중장", "장관"},
    {"general", "대장", "장관"},
}
local colors: {[string]: {number}} = {
    ["훈련병"]={190,198,190}, ["병"]={212,225,204}, ["부사관"]={235,199,110},
    ["준사관"]={237,214,158}, ["위관"]={217,224,234},
    ["영관"]={210,220,235}, ["장관"]={246,221,137},
}
local ordered: {Rank} = {}
local byId: {[string]: Rank} = {}
for order, entry in definitions do
    local symbol="training"
    local marks=0
    if order >= 2 and order <= 5 then symbol="bars"; marks=order-1
    elseif order >= 6 and order <= 9 then symbol="chevrons"; marks=math.min(3,order-5)
    elseif order == 10 then symbol="diamond"; marks=1
    elseif order <= 13 and order >= 11 then symbol="diamond"; marks=order-10
    elseif order <= 16 and order >= 14 then symbol="flower"; marks=order-13
    elseif order >= 17 then symbol="star"; marks=order-16 end
    local rank: Rank = {id=entry[1], name=entry[2], category=entry[3],
        order=order, color=table.clone(colors[entry[3]]), symbol=symbol, marks=marks}
    table.freeze(rank.color)
    table.freeze(rank)
    table.insert(ordered,rank)
    byId[rank.id]=rank
end
local Catalog = {
    DefaultId="trainee", All=table.freeze(ordered),
}
function Catalog.find(id: any): Rank?
    if type(id) ~= "string" then return nil end
    return byId[id]
end
return table.freeze(Catalog)

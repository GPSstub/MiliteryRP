--!strict
local Catalog=require("../src/shared/RankCatalog")
local expected={"훈련병","이병","일병","상병","병장","하사","중사","상사","원사","준위","소위","중위","대위","소령","중령","대령","준장","소장","중장","대장"}
assert(#Catalog.All==20)
assert((Catalog :: any).BattalionName==nil)
local seen: {[string]: boolean}={}
for i,rank in Catalog.All do
    assert(rank.name==expected[i] and rank.order==i)
    assert(not seen[rank.id]); seen[rank.id]=true
    assert(Catalog.find(rank.id)==rank)
    assert(#rank.color==3)
    assert(type(rank.symbol)=="string" and rank.marks>=0 and rank.marks<=4)
end
assert(Catalog.find(Catalog.DefaultId)==Catalog.All[1])
assert(Catalog.find("unknown")==nil)
assert(Catalog.find(1)==nil)
assert(Catalog.find({})==nil)
assert(Catalog.find(nil)==nil)
local ok=pcall(function() (Catalog.All[1] :: any).name="변조" end)
assert(not ok)
print("PASS: 20 ranks, unique IDs/order/colors, no team dependency, default, invalid input and immutable catalog")

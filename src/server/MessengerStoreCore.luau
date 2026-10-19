--!strict
-- Adapter-driven transactional persistence, exercised with an in-memory fault-injecting store.
local Core={}
function Core.new(rules: any, adapter: any): any
    local self={data=rules.default(),ready=false,busy=false,error="설정을 불러오는 중입니다."}
    local function accept(data)
        if not rules.valid(data) then return false end
        if data.revision>=self.data.revision then self.data=rules.copy(data) end
        self.ready=true;self.error=""
        return true
    end
    function self:load(): boolean
        if self.busy then return false end
        self.busy=true
        local ok,value=pcall(adapter.get)
        self.busy=false
        if ok and accept(if value==nil then rules.default() else value) then return true end
        self.ready=false;self.error="저장소를 불러오지 못했습니다. 관리 변경은 잠겨 있습니다."
        return false
    end
    function self:commit(actor: any, op: any, expected: any): (boolean,string)
        if not self.ready or self.busy then return false,"설정 로딩 또는 저장 중입니다. 새로고침 후 시도하세요." end
        if type(expected)~="number" or expected%1~=0 or expected~=self.data.revision then return false,"다른 변경이 반영되었습니다. 새로고침 후 다시 시도하세요." end
        self.busy=true
        local operationId=adapter.id()
        local reason="저장 결과를 확인하지 못했습니다. 새로고침하여 상태를 확인하세요."
        for attempt=1,3 do
            local resultOk=false
            local ok,saved=pcall(function()
                return adapter.update(function(current)
                    local data=if current==nil then rules.default() else current
                    if not rules.valid(data) then reason="지원하지 않거나 손상된 저장 데이터입니다.";return nil end
                    for _,receipt in data.receipts do
                        if receipt.id==operationId then resultOk=true;return data end
                    end
                    if data.revision~=expected then reason="다른 서버에서 수정했습니다. 새로고침 후 다시 시도하세요.";return nil end
                    local changed,message=rules.apply(data,actor,op)
                    reason=message
                    if not changed then return nil end
                    table.insert(changed.receipts,{id=operationId})
                    if #changed.receipts>64 then table.remove(changed.receipts,1) end
                    if not rules.valid(changed) then reason="설정 데이터 검증 실패";return nil end
                    resultOk=true
                    return changed
                end)
            end)
            if ok then
                if resultOk and saved and accept(saved) then self.busy=false;return true,"영구 저장 완료" end
                self.busy=false
                self:load() -- conflict reload; never overwrite a newer revision with a cached snapshot
                return false,reason
            end
            if attempt<3 then adapter.wait(0.4*2^(attempt-1)) end
        end
        self.busy=false
        self:load() -- write outcome can be unknown; reconcile without claiming success
        return false,"저장 응답을 확인하지 못했습니다. 새로고침된 결과를 확인하세요."
    end
    return self
end
return Core

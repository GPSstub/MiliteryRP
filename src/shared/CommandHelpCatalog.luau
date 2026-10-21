--!strict
-- Display-only command reference. Never use this table to grant privileges.
-- Actual execution always goes through the server's group-rank checks.
local Catalog = {
    Sections = {
        {
            title = "계급 · 팀",
            entries = {
                {syntax = ";계급 나 대위  /  ;rank 나 captain", description = "내 계급 변경. 플레이어 이름을 넣으면 대상을 변경합니다."},
                {syntax = ";계급 대상 admin  /  ;rank 대상 admin", description = "대상에게 실제 admin 계급을 저장하면 HQ 팀으로 자동 배정됩니다."},
                {syntax = ";계급목록  /  ;ranks", description = "사용 가능한 계급 목록을 채팅에 표시합니다."},
                {syntax = ";팀 대상 본부  /  ;team 대상 본부", description = "대상을 지정한 팀으로 이동. 본부 등 7개 팀을 지원합니다."},
            },
        },
        {
            title = "운영진 제어",
            entries = {
                {syntax = ";무적 대상 켜기  /  ;god 대상 on", description = "무적 켜기·끄기 (끄기 또는 off)."},
                {syntax = ";비행 대상 켜기  /  ;fly 대상 on", description = "비행 켜기·끄기 (끄기 또는 off)."},
                {syntax = ";to 대상", description = "내가 대상 플레이어 옆으로 순간이동합니다."},
                {syntax = ";here 대상", description = "대상 플레이어를 내 위치로 소환합니다."},
                {syntax = ";kill 대상", description = "대상 플레이어를 사망 처리합니다."},
                {syntax = ";폭발 대상  /  ;explode 대상", description = "폭발 효과와 함께 대상 플레이어를 사망 처리합니다."},
            },
        },
        {
            title = "도움말",
            entries = {
                {syntax = ";?  /  ;help", description = "지금 보고 있는 명령어 안내창을 엽니다."},
            },
        },
    },
}
return table.freeze(Catalog)

# 국군 RP 카타나

Blender로 제작한 카타나와 분리된 칼집을 사용하는 기본 지급 근접 무기입니다.

- 장착 후 마우스 클릭 / 모바일 베기 버튼 / 게임패드 R2로 공격합니다.
- 피해량 30, 공격 간격 0.65초, 발도 대기 0.35초, 최대 거리 5.5스터드입니다.
- 장착하면 칼집에서 칼이 사라지고 손에 나타나며, 해제하면 허리 칼집에 돌아갑니다.
- 발도/베기 동작은 Tool.Grip 트윈으로 표현합니다. 별도의 업로드된 캐릭터 애니메이션은 없습니다.
- 베기 소리, 칼날 궤적, 상태 HUD, 명중 표시가 포함됩니다.
- 서버가 거리·방향·높이·시야·공격 속도·장착 상태·동일 팀을 검사합니다.
- 한 번의 베기에 같은 대상에게 한 번만 피해를 적용합니다. 해제/사망 시 대기 중인 공격을 취소합니다.

## 수동 설치

현재 프로젝트와 열린 Studio에는 이미 반영되어 있습니다. 다른 맵에서는 다음 위치에 파일 내용을 넣으세요.

- src/server/Katana.server.luau → ServerScriptService의 Script Katana
- src/server/KatanaMeshConfig.luau → ServerScriptService의 ModuleScript KatanaMeshConfig
- src/shared/KatanaRules.luau → ReplicatedStorage/Shared의 ModuleScript KatanaRules
- src/client/Katana.client.luau → StarterPlayer/StarterPlayerScripts의 LocalScript Katana

서버가 메시를 불러오고 Tool을 자동 생성합니다. 다른 경험으로 옮길 경우 메시/텍스처 사용 권한을 확인해야 합니다.
메시: 88881810229070, 칼집: 135559186550211, 텍스처: 71422577067667.
assets/katana에는 원본 Blender·GLB·텍스처가 있습니다.

## 검증

Luau 전체 소스 컴파일, 전체 순수 회귀 테스트, 맵 빌드 테스트 통과.
Studio 단일 플레이에서 기본 지급, 장착/해제, 근거리 30 피해, 중복 요청 제한, 뒤/거리 밖/벽 뒤 공격 거절, 공격 도중 해제 시 취소를 확인했습니다.
여러 실제 플레이어 간 복제, R6 아바타, 실제 모바일/게임패드 조작은 별도 검증이 필요합니다.
GitHub main에 소스와 맵을 반영합니다. Roblox 라이브 경험 게시는 별도로 수행해야 합니다.

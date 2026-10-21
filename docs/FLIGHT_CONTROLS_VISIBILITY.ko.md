# 비행 상승·하강 버튼 노출 버그 수정

## 원인
`MobileLayout.client.luau`의 이전 코드가 `FlightControls.Enabled = not modal`로 설정되어 있었습니다. 창을 닫거나 모바일 레이아웃이 새로고침될 때 `AdminFlying=false`여도 FlightControls GUI를 다시 켰습니다. `AdminFlight.client.luau`와 `MobileLayout.client.luau`가 **서로 같은 Enabled 속성을 덮어쓴 것**이 문제였습니다.

## 해결
- `AdminFlight.client.luau`만 FlightControls.Enabled 값을 설정합니다.
- 초기 GUI는 무조건 비활성화하고, 서버가 플레이어에게 복제한 `AdminFlying==true`일 때만 표시합니다.
- `MobileLayout.client.luau`는 비행 GUI 자체를 켜지 않고 `HiddenByModal` Attribute로 다른 창의 가림 상태만 전달합니다.
- 비행 버튼이 보이는 조건은 `src/shared/FlightControlsRules.luau`에 고정해 회귀 테스트를 추가했습니다.
- 비행 해제 또는 모달 진입 시 눌린 상승/하강 입력 상태도 초기화합니다.
- 모바일에서 FlightControls가 나중에 생성돼도 기존 모달 표시 상태를 다시 전달합니다.

## 검증
1. Roblox Studio **Stop → Play**로 실행을 완전히 다시 시작합니다.
2. 비행하지 않은 상태에서 메뉴, 시험, 통신 창을 열었다 닫아도 **상승/하강 버튼이 없어야 합니다**.
3. `;fly 나 on` 또는 `;비행 나 켜기`를 실행하면 상승/하강 버튼이 보여야 합니다.
4. 비행 도중 모바일에서 전체화면 메뉴를 열면 숨고 닫으면 다시 보여야 합니다.
5. `;fly 나 off` 또는 `;비행 나 끄기` 실행 시 즉시 사라져야 합니다.
6. 리스폰과 사망 뒤에도 비행이 아닐 때 버튼이 없어야 합니다.

`MilitaryRP.rbxlx` 완성 맵 파일은 이 수정에서 변경하지 않습니다. Rojo로 최신 클라이언트 코드를 동기화한 다음 새 Play 세션으로 테스트합니다.

# ;team / ;rank 영어 명령어와 ;? 명령어 도움말

## 사용 방법
Roblox **TextChatService** 채팅 입력창에 다음과 같이 입력합니다.

| 명령 | 영어 별칭 | 설명 |
|---|---|---|
| \`;계급 나 대위\` | \`;rank 나 captain\` | 본인 실제 계급 변경 |
| \`;계급 대상 admin\` | \`;rank 대상 admin\` | 대상 admin 계급 저장 → HQ 자동 배정 |
| \`;계급목록\` | \`;ranks\` | 모든 계급 목록 |
| \`;팀 대상 본부\` | \`;team 대상 본부\` | 현재 서버에서 본부 팀 수동 배정 |
| \`;무적 대상 켜기\` | \`;god 대상 on\` | 무적 on/off |
| \`;비행 대상 켜기\` | \`;fly 대상 on\` | 비행 on/off |
| \`;to 대상\` | - | 대상으로 순간이동 |
| \`;here 대상\` | - | 대상을 자신에게 소환 |
| \`;kill 대상\` | - | 대상 사망 |
| \`;폭발 대상\` | \`;explode 대상\` | 폭발 효과와 함께 대상 사망 |
| **\`;?\`** | **\`;help\`** | 화면에 별도 명령어 목록 UI 표시 |

\`;?\`는 서버가 만든 \`TextChatCommand\`에서 처리하고, 도움말 전용 \`RemoteEvent\`로 요청한 플레이어에게만 UI를 표시합니다. 일반 채팅 메시지를 다른 사람에게 보내지 않습니다. 도움말 UI는 PC/모바일/게임패드에서 스크롤할 수 있고 X, Esc, 게임패드 B로 닫을 수 있습니다.

### 권한
도움말 열람은 누구나 가능하지만 **명령어 실행은 Roblox 그룹 1101574390에서 200 이상**만 허용합니다. HQ 팀이나 \`admin\` 계급을 얻었다고 관리자 명령 권한이 생기지 않습니다.

### 구현 파일
- \`src/server/CommandHelp.server.luau\`: \`;?\` / \`;help\` 채팅 명령어 등록, 권한 정보와 UI 신호 전송
- \`src/client/MilitaryCommandHelp.client.luau\`: 별도 Scrollable UI
- \`src/shared/CommandHelpCatalog.luau\`: 명령어 목록 단일 데이터 정의
- \`src/server/AdminService.luau\`: \`;팀\` / \`;team\` 실행 및 권한 확인 (기존 동작)
- \`src/server/RankCommands.luau\`: \`;계급\` / \`;rank\` 실행 및 권한 확인 (기존 동작)
- \`tests/command-help.spec.luau\`, \`tests/commands.spec.luau\`: 문서화된 별칭/계급 파서 검사

### 검증
GitHub Actions에서 Luau 컴파일·순수 테스트를 수행합니다. 실제 Studio에서는 Rojo 연결 후 Play 재시작, \`;?\` 입력 시 별도 팝업 생성, \`;team 나 본부\` 및 \`;rank 나 대위\` 작동, 비관리자에게 실행 차단을 확인해야 합니다. 외부에 저장된 \`MilitaryRP.rbxlx\` 안의 이전 스크립트는 Rojo 동기화 없이 자동으로 바뀌지 않습니다.

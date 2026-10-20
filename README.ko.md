# MilitaryRP

군용 메신저의 채널·역할·권한 관리와 DataStore 영구 저장을 구현했습니다. 채널 목록의 `+` 또는 설정에서 생성·이름 변경·삭제하고, 역할별 읽기·쓰기·관리와 사용자별 역할을 지정할 수 있습니다. **채널 생성 때 '영구 보관'을 선택하면 공지·규칙 게시판처럼 기록이 유지됩니다.** 일반 채널은 기록을 저장하지 않습니다.

**[메신저 사용법·저장 구조·비공개 테스트 게시 안내](docs/MESSENGER.ko.md)** · **[영구 보관 채널 만들기](docs/MESSENGER_ARCHIVE.ko.md)** · **[HQ 팀/어드민 패널](docs/HQ_TEAMS_ADMIN.ko.md)** · **[영구 채팅·명령어 로그](docs/HQ_SERVER_LOGS.ko.md)** · **[간편 역할 부여/채널 이름 오류 수정](docs/MESSENGER_ROLES.ko.md)** · **[HQ 머리 위 로고 적용](docs/HQ_OVERHEAD.ko.md)**

저장 서비스가 연결되지 않으면 메신저 설정 변경과 메시지 전달을 잠그며, 기본 Roblox 채팅은 유지됩니다. 실제 Roblox 저장/다중 사용자 검증은 별도의 테스트 경험에서 진행하세요.

## 계급 시스템

현재 소스 프로젝트: `MilitaryRP.rbxlx`. 기존 MilitaryRP 창에도 동일 기능을 적용했다. 이전 전투 MVP 원본은 `korean-military-rp.zip`에 보관되어 있다.

## 구현

- 훈련병부터 대장까지 20개 계급.
- 머리 위 이름, 참고 이미지 기반 도형 계급장, 계급명 표시. **HQ 소속자는 일반 계급 표시 대신 거북이·고양이 HQ 로고 + `HQ`만 표시**합니다. 팀 HQ에 있는 동안 플레이어 목록 및 `Rank` 속성의 계급은 **`admin`**으로 표시되며, 원래 군 계급은 영구 저장된 상태로 유지됩니다. 로고 이미지는 Roblox Asset Manager에 `HQLogo.png`로 업로드하면 적용됩니다.
- 병: 검은 가로줄 1~4개, 부사관: 금색 갈매기와 장식, 준위: 금색 다이아몬드, 위관: 은색 다이아몬드 1~3개, 영관: 은색 꽃 1~3개, 장성: 별 1~4개.
- 계급장은 제공된 참고의 모양을 게임 GUI 도형으로 재현한 것이며 공식 그림 파일 자체를 복제하거나 업로드하지 않았다. 훈련병은 계급장 없이 이름과 계급명만 표시한다.
- Roblox 기본 플레이어 목록에 계급 표시.
- Roblox Teams에 HQ·위관급·영관급·장관급 4팀을 구현. 계급별 자동 편제와 HQ 전용 관리자 권한이 적용되며, 기존 큰 HUD·훈련/XP/탄약/분대 버튼은 없음.
- 계급 자동 진급은 아직 없음. 계급은 사용자별 DataStore에 즉시 영구 저장되며, 메신저 설정도 별도 DataStore에 저장됨.

처음 접속한 플레이어는 훈련병으로 시작합니다. 이후 계급 명령어로 변경한 계급은 저장이 성공한 뒤 적용되며, 리스폰·재접속·서버 재시작 후에도 복원됩니다. Roblox API 연결 실패 시 기존 저장 데이터를 덮어쓰지 않고 오류를 표시합니다. Studio와 실제 게임은 서로 다른 계급 DataStore를 사용합니다.

## HQ 전용 채팅 명령어

현재 HQ 팀에 배정된 플레이어만 명령어를 사용할 수 있습니다. Studio에서 Play를 시작하고 채팅에 입력합니다.

| 명령 | 동작 |
|---|---|
| `/계급 대위` | 내 계급을 대위로 변경 |
| `/계급 플레이어명 병장` | 현재 서버의 정확한 Roblox 사용자 이름에 해당하는 플레이어 변경 |
| `/계급 나 원사` | 내 계급 변경 |
| `/계급목록` | 20개 계급 이름 확인 |
| `/rank captain`, `/ranks` | 영어 별칭 |

명령어 실행자는 로컬 Studio에서 확인한 본인 계정 `pikachu6361phw` (UserId `1153125948`)으로 한정했다. 이는 계급 변경 명령어만의 제한이며 군대 계급별 권한 시스템은 아니다. 다른 계정을 사용할 때는 서버 파일 `RankCommands.luau`의 `COMMAND_OWNER_USER_ID`를 바꾼다. 계급은 한글 명칭 또는 내부 영문 ID로 지정할 수 있다. 이름 일부나 DisplayName 추측 매칭은 하지 않는다.

### 계급 영구 저장 테스트

비공개 테스트 게임을 Roblox에 게시한 뒤 **Game Settings → Security → Enable Studio Access to API Services**를 켜고 저장하세요. Studio 버전에 따라 **File → Game Settings** 경로로 이동해야 할 수 있습니다. 테스트용 경험을 따로 사용하세요.

Studio에서 `/계급 대위`를 실행하고 성공 메시지가 표시되면 Stop → Play로 재접속해서 계급을 확인합니다. Explorer의 Players → 본인 플레이어 → Attributes에서 `RankStorageStatus`가 `Ready`인지 확인할 수 있습니다. `Error`이면 Output의 `[RankStore]` 경고와 API 설정을 확인하세요.

저장소 이름은 Studio에서 `MilitaryRP_Ranks_Dev_v1`, 실제 공개/비공개 서버에서는 `MilitaryRP_Ranks_v1`이며 키는 `user_<UserId>` 형식입니다. 최초 접속 시 훈련병을 화면에 임시 표시했다가 저장된 계급을 불러옵니다. **일반 채팅 기록은 영구 저장하지 않습니다. 공지사항 및 관리자가 영구 보관을 선택한 채널의 게시글만 별도 DataStore에 저장됩니다.**

## 계급표

| 구분 | 계급 |
|---|---|
| 시작 | 훈련병 |
| 병 | 이병 · 일병 · 상병 · 병장 |
| 부사관 | 하사 · 중사 · 상사 · 원사 |
| 준사관 | 준위 |
| 위관 | 소위 · 중위 · 대위 |
| 영관 | 소령 · 중령 · 대령 |
| 장관 | 준장 · 소장 · 중장 · 대장 |

표시 순서이며 자동 진급 경로를 뜻하지 않는다.

## 소스와 재생성

- `src/shared/RankCatalog.luau`: 계급 정의.
- `src/server/RankService.luau`: 서버 계급과 표시 동기화, 접속 시 복원, 리스폰/외형 교체 대응.
- `src/server/RankStore.luau`: 사용자별 계급 DataStore GetAsync/UpdateAsync 영구 저장.
- `src/server/RankInsignia.luau`: 업로드 없이 GUI 도형으로 계급장 렌더링.
- `src/server/RankCommandParser.luau`, `RankCommands.luau`: 입력 해석, 실행자 확인, 변경 명령어.
- `src/server/Main.server.luau`: 초기화.
- `src/client/RankFeedback.client.luau`: Roblox 기본 채팅에 명령 결과 표시. 별도 창을 만들지 않는다.

```sh
python3 tools/build_place.py
```

생성 파일은 현대 TextChatService를 사용하도록 설정되어 있다. 오래된 Roblox XML 파일은 기본값이 LegacyChatService일 수 있으므로 명령어가 안 되면 Edit 모드에서 TextChatService의 ChatVersion이 TextChatService인지 확인한다. 일반 게임 스크립트에서 이 보호된 설정을 바꾸지 않는다.

Rojo 동기화는 `default.project.json`을 사용한다. 임시 바닥/스폰만 있으며 맵은 만들지 않았다.

## 설치한 개발 스킬

[MSayib/roblox-dev-skill](https://github.com/MSayib/roblox-dev-skill) 2.18.1, 고정 커밋 `4a35b01cb07eb237081bee705455e19db37342d8`을 Codex 기본 설치 도구로 설치했다. 설치 위치는 `~/.codex/skills/roblox-dev-skill`이다. 저장소의 자체 설치 스크립트는 실행하지 않았다. 다음 턴부터 자동 탐지되며 이번에는 설치된 지침을 직접 읽었다.

공식 Studio 플러그인 패키지와 EL4CTEO의 23개 모음은 미설치다. Studio 내장 MCP는 별도로 연결되어 있다.

# HQ 영구 서버 로그 — 채팅 / 관리자 명령

작업 브랜치: [main](https://github.com/GPSstub/MiliteryRP/tree/main)

## 사용법

1. **HQ 팀**으로 게임에 접속합니다.
2. `메뉴 → HQ 관리 패널 → 기록`으로 이동합니다.
3. **채팅 로그** / **명령어 로그**를 각각 선택합니다.
4. `최신 기록 새로고침`으로 가장 최근 기록부터 다시 읽고, `더 오래된 기록 15개 불러오기`를 반복하면 이전 기록을 계속 볼 수 있습니다.

게임에서 나간 뒤 다시 접속하거나 다른 Roblox 서버로 이동해도 같은 경험(Universe)의 저장된 로그를 불러올 수 있습니다. 조회 시점에 모든 기록을 한꺼번에 다운로드하지 않으며 **15개씩 페이지를 순차적으로 요청**합니다.

## 무엇이 기록되나요?

**채팅 로그**: 게임의 군용 메신저 `RP_...` 채널에서 서버가 정상 배달 대상으로 판단한 메시지, 수정 메시지 이벤트, 영구 게시판(공지·규칙 등)에 성공적으로 저장된 글과 수정 글. 글 삭제 및 고정/해제와 같은 **메시지 관리 이벤트**도 별도 항목으로 기록합니다. 서버는 로그 저장 전에 **Roblox 텍스트 필터링**을 별도로 수행합니다. 텍스트 필터링이 실패하면 원본 문장을 저장하지 않습니다.

**명령어 로그**: HQ 사용자가 Roblox 채팅창 또는 어드민 패널에서 입력한 `;계급`, `;계급목록`, `;팀`, `;무적`, `;비행`, **`;to`, `;here`, `;kill`, `;폭발`** 등 서버 관리 명령의 실행 내용과 성공/실패 여부. 원문을 그대로 저장하지 않고 Roblox 필터가 승인한 텍스트만 보관합니다.

**제외**: Roblox 기본 `RBXGeneral` 채팅창의 일반 대화, 기본 팀 채팅, Whisper/DM, 서버 Output/Studio 개발자 콘솔 오류, 관리자 명령으로 인식되지 않는 기타 채팅 명령. 기본 Roblox 채팅을 몰래 수집하기 위해 기본 채팅 콜백을 덮어쓰지 않습니다. `;계급` 같은 관리자 명령은 별도의 감사 이벤트로 기록됩니다.

## 개인정보와 접근 제어

- HQ 팀 멤버만 `AdminLogRequest`의 로그 조회 요청을 보낼 수 있습니다. 클라이언트에서 관리 패널을 강제로 활성화해도 서버에서 거절합니다.
- 일반 사용자에게 로그 RemoteFunction 응답을 전달하지 않습니다.
- **부대 전용 `unit` 채팅**의 본문은 해당 부대 권한이 있는 HQ 멤버에게만 표시합니다. 다른 부대이거나 채널 열람 권한이 없다면 시간·작성자·채널 같은 감사 메타데이터만 보이고 본문은 가려집니다.
- 접근할 수 없는 비공개/삭제된 채널의 본문도 가립니다.
- 채팅 본문은 `TextService:FilterStringAsync(...):GetNonChatStringForBroadcastAsync()`가 성공한 경우에만 저장합니다. 전송 중 정상 필터링과 별도로, 기록 보관용으로 재필터링하는 구조입니다.

## 저장 구조

Studio 개발 테스트와 실제 서버는 다른 저장소를 사용합니다.

| 저장소 | Studio | 실제 게임 |
|---|---|---|
| 본문 로그 DataStore | `MilitaryRP_AdminLogRecords_Dev_v1` | `MilitaryRP_AdminLogRecords_v1` |
| 채팅 로그 OrderedDataStore | `MilitaryRP_AdminLogChat_Dev_v1` | `MilitaryRP_AdminLogChat_v1` |
| 명령어 로그 OrderedDataStore | `MilitaryRP_AdminLogCommands_Dev_v1` | `MilitaryRP_AdminLogCommands_v1` |

하나의 로그 이벤트는 GUID로 생성한 키에 **필터링된 본문**을 저장한 다음, 같은 키를 OrderedDataStore에 시간순 인덱스로 등록합니다. 서버는 저장 작업을 비동기 큐에 넣고 재시도하며, 종료 직전에도 남은 작업을 최대 20초간 기다립니다.

**개수/보관 기간을 인위적으로 60개 또는 300개로 자르지 않았습니다.** 따라서 과거 기록을 페이지마다 차례로 계속 조회할 수 있습니다. 단, 로그를 설치한 시점 **이전의 이미 사라진 채팅 기록은 복구할 수 없습니다.**

## 꼭 알아야 할 한계

Roblox DataStore는 무제한·완전한 감사 로그 시스템이 아닙니다.

- 요청 수, 저장량, 데이터 처리량, 동시성 제한이 존재합니다. 채팅량이 많은 게임에서는 기록 저장이 지연되거나 실패할 수 있습니다.
- 개별 이벤트의 DataStore 본문 쓰기와 OrderedDataStore 인덱스 쓰기는 **하나의 원자적 트랜잭션이 아닙니다**. 드문 서버 종료/장애 시 본문이 저장되었어도 인덱스 조회에 나타나지 않을 수 있습니다.
- 저장 서버가 불안정할 때 재시도하고 상태(대기·실패·큐 초과)를 HQ 화면에 표시하지만, **100% 무손실을 보장하지는 않습니다.**
- 대량 장기 보존·완전한 규정 준수 감사나 모든 서버 Output 기록을 저장하려면 외부 전문 로그 저장소와 별도 운영 정책이 필요합니다.
- 유저가 기존 채팅/공지 기록을 삭제해도 로그는 **자동으로 함께 삭제되지 않습니다**. 개인정보 및 보존 정책, 삭제 요청 대응이 필요할 수 있습니다.

## 배포 및 검증

```bash
git status --short
git switch main
git pull --ff-only origin main
rojo serve default.project.json
```

Studio를 연결하고 테스트 경험을 게시합니다. **Game Settings → Security → Enable Studio Access to API Services**를 켜야 Studio에서 DataStore를 사용할 수 있습니다. 테스트 경험과 실제 게임에서 데이터를 구분하며, 실제 프로덕션 데이터는 테스트용으로 지우지 않습니다.

1. HQ 계정으로 Play → `ReplicatedStorage.AdminLogRequest` RemoteFunction 확인.
2. 메신저 일반 채널에 메시지 2개 작성, HQ 패널에서 **기록 → 채팅 로그 → 새로고침**으로 확인.
3. HQ로 `;계급목록` 또는 `;무적 나 켜기`를 수행 → **명령어 로그**에서 성공/실패 여부 확인.
4. Studio에서 Stop → Play로 재접속 후에도 이전 두 종류의 로그가 표시되는지 확인.
5. 서로 다른 서버에서 작성한 기록도 같은 데이터 목록에 나타나는지 확인.
6. HQ 팀에서 빠진 계정은 `AdminLogRequest` 조회를 거절당하고 패널이 닫혀야 합니다.
7. 비공개 채널의 읽기 권한이 없는 HQ에게 본문이 가려지는지 확인.
8. 로그 15개를 넘겨 `더 오래된 기록 불러오기` 버튼으로 여러 페이지를 순회.
9. Roblox DataStore 오류가 나면 `Output`의 `[AdminLogs]` 경고 및 패널의 저장 대기/실패 표시를 확인.

## 개발용 순수 테스트

```bash
python3 tools/test.py
```

로컬 실행에는 Roblox 공식 Luau CLI (`luau`, `luau-compile`)가 필요합니다. `tests/admin-logs.spec.luau`는 로그 분류·데이터 형식 검증·부대 전용 열람 차단을 검사합니다.

**현재 검증 상태:** 코드는 GitHub에 반영되었고 정적 구조를 검사했지만, 이 환경에서는 Roblox Studio/공식 Luau CLI에 접근할 수 없어 실제 저장/재접속 통합 테스트는 아직 수행하지 못했습니다.

## 공식 참고 문서

- [Roblox OrderedDataStore/GetSortedAsync](https://create.roblox.com/docs/reference/engine/classes/OrderedDataStore/GetSortedAsync)
- [Roblox TextChannel/ShouldDeliverCallback](https://create.roblox.com/docs/reference/engine/classes/TextChannel)
- [Roblox 텍스트 필터링](https://create.roblox.com/docs/ko-kr/ui/text-filtering)
- [Roblox DataStore 제한](https://create.roblox.com/docs/cloud-services/data-stores/error-codes-and-limits)

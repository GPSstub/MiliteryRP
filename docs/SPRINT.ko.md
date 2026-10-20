# MilitaryRP 달리기(스프린트) 기능

GitHub 대상 브랜치: [main](https://github.com/GPSstub/MiliteryRP/tree/main)

## 사용법

| 입력 | 동작 |
|---|---|
| PC: **왼쪽 Shift / 오른쪽 Shift** | 누르고 있는 동안 달리기, 떼면 걷기 |
| 모바일: 화면의 **달리기** 버튼 | 한 번 누르면 달리기, 다시 누르면 걷기 |
| 게임패드: **왼쪽 스틱 클릭(L3)** | 누를 때마다 달리기/걷기 전환 |

- 기본 걷기 속도: **16 studs/s** (`Humanoid.WalkSpeed`)
- 달리기 속도: **24 studs/s**
- **지구력 소모·스태미나·달리기 전용 애니메이션은 아직 없습니다.** Roblox 기본 이동 애니메이션을 사용합니다.
- 모든 플레이어와 팀에서 사용할 수 있으며 HQ 전용은 아닙니다.
- 사망, 리스폰, 탑승, 텍스트 입력 시작, 게임 창 포커스 해제 시 달리기가 취소됩니다.
- HQ 관리자 **비행(`AdminFlying`) 시작 시 달리기가 해제**되어 비행과 이동속도 변경이 충돌하지 않습니다.
- 이동속도는 서버가 직접 `Humanoid.WalkSpeed`에 적용합니다. 클라이언트는 속도 숫자가 아니라 `true/false`만 전송합니다. 비정상 입력은 무시합니다.

## 파일 구성

- `src/shared/SprintConfig.luau` — 걷기/달리기 속도 설정
- `src/shared/SprintRules.luau` — 달리기 가능 상태 판정
- `src/server/SprintService.luau` — 서버 이동속도 변경, 검증, 리스폰/사망·착석 초기화
- `src/client/MilitarySprint.client.luau` — Shift, 모바일 버튼, 게임패드 입력 및 UI
- `src/server/Main.server.luau` — 서버 SprintService 초기화
- `tests/sprint.spec.luau` — 순수 정책 회귀 테스트
- `tests/studio/sprint-check.luau` — Studio SERVER Command Bar 상태 검사

Rojo의 `default.project.json`에서 `src/server`, `src/client`, `src/shared`가 자동 연결되므로 기존 프로젝트 파일 경로를 변경할 필요가 없습니다. 서버가 실행될 때 `ReplicatedStorage.SprintRequest` RemoteEvent가 생성됩니다.

## 속도 변경

`src/shared/SprintConfig.luau`의 숫자만 수정합니다.

```luau
WalkSpeed=16,
SprintSpeed=24,
```

클라이언트에서 WalkSpeed를 임의로 정하는 구조는 사용하지 마세요. 서버 검증 없이 사용자가 숫자 속도를 보내면 비정상적인 이동 요청을 허용하게 됩니다.

## GitHub main 적용

```bash
git status --short
git switch main
git pull --ff-only origin main
rojo serve default.project.json
```

먼저 `git status --short`로 로컬 수정 파일을 확인하고 필요한 작업을 보존하세요. Studio에서 Rojo를 다시 연결한 뒤 **Stop → Play**로 새로 시작합니다.

## Studio 테스트 체크

1. Play 후 `ReplicatedStorage.SprintRequest`가 만들어졌는지 확인합니다.
2. 캐릭터 `Humanoid.WalkSpeed`가 기본 **16**인지 확인합니다.
3. **Shift를 누르는 동안 24**, 놓으면 **16**으로 돌아오는지 확인합니다.
4. Shift를 누른 상태로 사망/리스폰하거나 앉아도 달리기가 유지되지 않는지 확인합니다.
5. 관리자 비행을 켰을 때 달리기가 강제로 꺼지고 비행이 정상 동작하는지 확인합니다.
6. 모바일 기기 에뮬레이터에서 **달리기** 버튼이 나타나고 탭하면 속도가 전환되는지 확인합니다.
7. 게임패드 L3 입력이 적용되는지 확인합니다.
8. 2인 서버에서 각 플레이어의 달리기가 다른 플레이어의 속도를 바꾸지 않는지 확인합니다.
9. `tests/studio/sprint-check.luau`를 Studio **서버** Command Bar에서 실행해 결과를 확인합니다.
10. 공식 Luau CLI가 있다면 `python3 tools/test.py`로 순수 규칙 테스트와 전체 소스 컴파일을 실행할 수 있습니다.

**검증 상태:** GitHub 소스와 테스트 코드 추가는 완료했지만, 이 환경에서 Roblox Studio로 실제 Play 테스트를 실행하지는 못했습니다.

공식 Roblox API: [Humanoid.WalkSpeed](https://create.roblox.com/docs/reference/engine/classes/Humanoid#WalkSpeed), [ContextActionService](https://create.roblox.com/docs/reference/engine/classes/ContextActionService).

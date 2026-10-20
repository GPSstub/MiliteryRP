# HQ 팀 머리 위 로고 + HQ 표시

적용 브랜치: [main](https://github.com/GPSstub/MiliteryRP/tree/main)

## 동작

- `Teams.HQ` 소속이고 `Player.Neutral == false`인 플레이어만 머리 위에 **거북이·고양이 HQ 엠블럼과 'HQ' 텍스트**가 표시됩니다.
- HQ 소속 동안에는 **Roblox 플레이어 목록(leaderstats 계급)과 `Player.Rank` 속성에 `admin`**으로 표시됩니다. 일반 군 계급은 `RankId`, `RankCategory`, `RankOrder`에 남고 DataStore를 변경하지 않습니다. HQ에서 나가면 저장된 군 계급 표시가 돌아옵니다.
- HQ 멤버에게는 **기존 닉네임/일반 군 계급명/군 계급장**을 따로 표시하지 않습니다. 기존 기본 Roblox Humanoid 이름표도 숨깁니다.
- HQ에서 위관급·영관급·장관급 등 다른 팀으로 이동하면 **일반 닉네임+계급장+계급명** 표시로 되돌아갑니다.
- `/팀`으로 HQ에 임명하거나 HQ를 해제할 때, 플레이어가 리스폰하거나, 저장된 계급이 나중에 로드될 때도 자동으로 갱신됩니다. 렌더 순서를 검사해 이전 캐릭터의 머리 위 GUI가 다시 나타나는 현상을 줄였습니다.
- 이전 코드에서 `CharacterAppearanceLoaded`가 버전 번호를 전달하지 않아 머리 위 UI 재생성이 생략되던 문제를 수정했습니다. 서버 로그 저장 초기화가 실패하더라도 계급 표시 시스템이 시작되도록 초기화 순서를 조정했습니다.
- HQ 로고 렌더링이 실패하면 Output에 `[RankService] HQ badge render failed`가 표시되고, 최소한의 `HQ` 텍스트를 대신 표시합니다.
- 머리 위 HQ 이미지가 로드되지 않아도 파란색 거북이 등딱지와 고양이 얼굴을 조합한 간단한 **벡터형 대체 엠블럼**이 표시됩니다. 이미지가 클라이언트에서 정상 로드되면 대체 엠블럼은 자동으로 숨깁니다.

## 이전에 만든 파란색 HQ PNG를 Roblox에 연결하는 방법

Roblox의 `ImageLabel`은 ChatGPT 첨부 파일 경로나 GitHub PNG 주소를 그대로 쓸 수 없습니다. **Roblox 게임에서 사용할 수 있도록 이미지 에셋으로 업로드**해야 합니다.

### 방법 A — 숫자 에셋 ID를 편집하지 않고 적용 (권장)

1. 이 대화에서 제공된 **`HQLogo.png`**를 Mac에 저장합니다. 파란색 고양이·거북이 HQ 로고의 원본 내용 그대로이며, 파일명만 Roblox에 맞춰 바꾸었습니다.
2. Roblox Studio에서 **Asset Manager → Images**로 이동한 뒤 **`HQLogo.png`**를 가져옵니다. 해당 경험에 사용할 권한이 있는 계정으로 업로드해야 합니다.
3. 이미지가 검열/승인되고 사용할 수 있게 된 뒤 경험을 다시 실행합니다.
4. `src/shared/HQLogoConfig.luau`에 `LogoAssetId=0`, `LogoGameAssetName="HQLogo"` 상태라면 `rbxgameasset://Images/HQLogo` 경로를 통해 그 경험의 이미지를 로드합니다. 코드에 숫자 ID를 넣을 필요가 없습니다.

### 방법 B — 숫자 에셋 ID로 적용

Roblox Creator Dashboard 또는 Studio Asset Manager에서 승인된 이미지의 **Asset ID**를 얻은 뒤:

```lua
-- src/shared/HQLogoConfig.luau
LogoAssetId = 1234567890, -- 실제로 발급받은 이미지 ID로 교체하세요.
```

이 값이 0보다 크면 ID를 우선 사용합니다. 다른 Roblox 경험에서 사용하는 로고에도 유리합니다. 위 숫자는 예시이며 실존 로고 ID가 아닙니다.

**주의:** 승인 전에는 이미지가 표시되지 않을 수 있고, 해당 경험에서 사용할 이미지 권한이 없다면 대체 엠블럼만 보일 수 있습니다.

## 적용과 테스트

```bash
git status --short
git switch main
git pull --ff-only origin main
rojo serve default.project.json
```

Rojo로 Studio에 코드를 동기화한 다음, 다음 항목을 확인합니다.

1. HQ 팀으로 Play를 시작하면 머리 위 `RankTag`의 `DisplayMode`가 `HQ`, `HQLabel.Text`가 `HQ`인지 확인합니다. `HQEmblem` 내부에 이미지 또는 대체 로고가 보입니다. 플레이어 `Rank` 속성과 리더보드의 `계급` 값은 `admin`이어야 합니다.
2. HQ 관리 패널에서 다른 플레이어를 `HQ`로 이동시켜 같은 표시가 나타나는지 확인합니다.
3. 해당 플레이어를 `위관급` 등으로 이동하면 머리 위 HQ 표시가 사라지고 평소 계급장과 **원래 군 계급 값**이 돌아와야 합니다. `RankId`가 HQ 전후로 바뀌지 않는 것도 확인하세요.
4. HQ 멤버가 리스폰해도 로고와 HQ 표시가 유지되는지 확인합니다.
5. 이미지 승인 후 Studio에서 Play를 다시 시작해 **대체 로고 대신 실제 `HQLogo.png`**가 표시되는지 확인합니다.
6. 서버 Command Bar에서 `tests/studio/hq-overhead-check.luau` 내용을 실행해 `[HQ OVERHEAD] Passed ... assertions`를 확인합니다.

대상 파일: `src/server/RankService.luau`, `src/server/HQOverheadBadge.luau`, `src/shared/HQLogoConfig.luau`, `src/client/HQLogoLoading.client.luau`

**여전히 머리 위가 비어 있다면:** Studio에서 **View → Output**을 열고 `[RankService]`, `[Main]` 오류를 확인하세요. Explorer의 `Players → 본인 → Team`이 실제 `HQ`이고 `Neutral=false`인지, Workspace 캐릭터 `Head → RankTag`에 `HQLabel`이 있는지도 확인해 주세요.

**검증 상태:** GitHub 소스 수정과 구조 검사는 완료했지만, 이 환경에서는 Roblox Studio 및 Luau CLI 실행 통합 테스트를 하지 못했습니다.

공식 문서: [Roblox ImageLabel](https://create.roblox.com/docs/reference/engine/classes/ImageLabel) / [Asset URI - rbxgameasset](https://create.roblox.com/docs/projects/assets)

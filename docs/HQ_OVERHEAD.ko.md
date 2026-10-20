# HQ 팀 머리 위 로고 + HQ 표시

적용 브랜치: [main](https://github.com/GPSstub/MiliteryRP/tree/main)

## 동작

- `Teams.HQ` 소속이고 `Player.Neutral == false`인 플레이어만 머리 위에 **거북이·고양이 HQ 엠블럼과 'HQ' 텍스트**가 표시됩니다.
- HQ 소속 동안에는 **Roblox 플레이어 목록(leaderstats 계급)과 `Player.Rank` 속성에 `admin`**으로 표시됩니다. 일반 군 계급은 `RankId`, `RankCategory`, `RankOrder`에 남고 DataStore를 변경하지 않습니다. HQ에서 나가면 저장된 군 계급 표시가 돌아옵니다.
- HQ 멤버에게는 **기존 닉네임/일반 군 계급명/군 계급장**을 따로 표시하지 않습니다. 기존 기본 Roblox Humanoid 이름표도 숨깁니다.
- HQ에서 위관급·영관급·장관급 등 다른 팀으로 이동하면 **일반 닉네임+계급장+계급명** 표시로 되돌아갑니다.
- `;팀`으로 HQ에 임명하거나 HQ를 해제할 때, 플레이어가 리스폰하거나, 저장된 계급이 나중에 로드될 때도 자동으로 갱신됩니다. 렌더 순서를 검사해 이전 캐릭터의 머리 위 GUI가 다시 나타나는 현상을 줄였습니다.
- 이전 코드에서 `CharacterAppearanceLoaded`가 버전 번호를 전달하지 않아 머리 위 UI 재생성이 생략되던 문제를 수정했습니다. 서버 로그 저장 초기화가 실패하더라도 계급 표시 시스템이 시작되도록 초기화 순서를 조정했습니다.
- HQ 로고 렌더링이 실패하면 Output에 `[RankService] HQ badge render failed`가 표시되고, 최소한의 `HQ` 텍스트를 대신 표시합니다.
- **최신 UI 크기:** 로고 60px, 표시 최대 거리 25스터드, 머리 기준 오프셋 2.35스터드. 예전에 겹치던 금색 원형 장식은 제거했습니다.
- HQ 로고를 로드하지 못하면 작은 파란색 임시 표식이 보입니다. 실제 투명 PNG를 불러오면 임시 표식은 자동으로 숨깁니다.

## 현재 HQ 로고 ID

요청한 Roblox 이미지 에셋 **`70816694077389`**를 HQ 로고에 적용했습니다.
현재 설정은 다음과 같습니다.

```lua
-- src/shared/HQLogoConfig.luau
LogoAssetId=70816694077389,
LogoGameAssetName="HQLogo_Transparent",
IconSize=60,
MaxDistance=25,
```

Roblox 이미지가 승인되어 현재 게임에 사용 권한이 있어야 실제 엠블럼이 보입니다. **원본 이미지 안에 흰색 바탕이 포함돼 있으면 `BackgroundTransparency=1`로는 제거할 수 없습니다.** 투명 PNG를 새로 업로드한 뒤 발급받은 ID로 `LogoAssetId`를 교체하세요.

숫자 ID를 사용하지 않으려면 `LogoAssetId=0`으로 바꾸고, Studio Asset Manager에 `HQLogo_Transparent`라는 이름의 이미지를 가져오면 됩니다. 미승인·불러오기 실패 시 작은 파란 대체 엠블럼이 나옵니다.

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
5. Roblox 이미지 `70816694077389`가 실제 표시되는지 확인합니다. 이미지 자체에 흰 배경이 있다면 새 투명 PNG를 업로드해 ID를 교체해야 합니다.
6. 서버 Command Bar에서 `tests/studio/hq-overhead-check.luau` 내용을 실행해 `[HQ OVERHEAD] Passed ... assertions`를 확인합니다.

대상 파일: `src/server/RankService.luau`, `src/server/HQOverheadBadge.luau`, `src/shared/HQLogoConfig.luau`, `src/client/HQLogoLoading.client.luau`

**여전히 머리 위가 비어 있다면:** Studio에서 **View → Output**을 열고 `[RankService]`, `[Main]` 오류를 확인하세요. Explorer의 `Players → 본인 → Team`이 실제 `HQ`이고 `Neutral=false`인지, Workspace 캐릭터 `Head → RankTag`에 `HQLabel`이 있는지도 확인해 주세요.

**검증 상태:** GitHub 소스 수정과 구조 검사는 완료했지만, 이 환경에서는 Roblox Studio 및 Luau CLI 실행 통합 테스트를 하지 못했습니다.

공식 문서: [Roblox ImageLabel](https://create.roblox.com/docs/reference/engine/classes/ImageLabel) / [Asset URI - rbxgameasset](https://create.roblox.com/docs/projects/assets)

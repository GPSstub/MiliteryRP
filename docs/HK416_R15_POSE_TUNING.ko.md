# HK416 R15 사진 기준 방향 및 크기 보정 (2026-10-21)

## 관찰과 수정

사용자가 제공한 R15 Play 스크린샷 2장:

- 1인칭: **개머리판이 화면 전방 위쪽으로 튀어나오고 총열/리시버가 시야를 크게 가림**. 장착 방향이 기대와 반대로 보임.
- 3인칭: 총 길이가 캐릭터 몸통 대비 과도하고, 왼손 지지 자세가 총과 어울리지 않음.

수정된 `src/server/TrainingRifle.server.luau`의 파라미터:

- `R15_GRIP_YAW_DEGREES=180`: Tool.Grip을 수평 180° 회전합니다. **바디 메시 자체는 회전시키지 않아서** 같은 Handle에 연결된 탄창, 노리쇠, 총구, IK 타깃이 모두 함께 움직입니다.
- `HK416_MESH_SCALE=0.64`: 약 5.71 studs 길이였던 HK416 바디를 **약 3.65 studs**로 축소합니다. 탄창, 노리쇠, 탄창 모터 기본 위치, 노리쇠 왕복, 탄창 분리 거리, 총구 위치, R15 왼손 타깃도 같은 비율로 줄였습니다.
- Handle 및 fallback 기본 Part 총은 그대로 둡니다.
- Tool Attributes로 `GripYawDegrees=180`, `HK416ModelScale=0.64`, `UsingHK416Mesh=true`가 제공됩니다.

## Studio 수동 점검

1. 최신 `main`을 Rojo에 동기화한 다음 기존 Play를 **Stop**하고 다시 Play를 시작합니다. **ServerStorage/HK416Assets/Body 및 Magazine은 지우지 않습니다.**
2. R15 아바타에서 총을 장착하고 3인칭 측면을 확인합니다. 이제 개머리판이 어깨/몸쪽, 총열은 캐릭터가 보는 방향을 향해야 합니다.
3. **1인칭**에서 총이 시야를 막는지 확인합니다. 모델 전체 길이는 기존 대비 64%입니다.
4. 총이 든 Tool의 `GripYawDegrees`, `HK416ModelScale`, `UsingHK416Mesh`, `UsingR15SupportIK` Attribute를 확인합니다.
5. **R 키로 재장전**할 때 탄창이 연결 상태를 유지하고 움직이는지 확인합니다.
6. **총구 방향 검사**: Play에서 Client Command Bar에 아래 코드를 붙여 실행하면 LocalPlayer가 든 Tool의 총구와 캐릭터 전방 벡터 일치 정도를 인쇄합니다.
   
```lua
local p = game:GetService("Players").LocalPlayer
local c = p and p.Character
local t = c and c:FindFirstChild("훈련용 소총")
local root = c and c:FindFirstChild("HumanoidRootPart")
local handle = t and t:FindFirstChild("Handle")
local muzzle = handle and handle:FindFirstChild("Muzzle")
assert(t and root and muzzle, "Equip the rifle first in Play mode")
local facing = muzzle.WorldCFrame.LookVector:Dot(root.CFrame.LookVector)
print("총구 전방 dot (-1 뒤, +1 앞):", facing)
print("UsingHK416Mesh",t:GetAttribute("UsingHK416Mesh"),
    "IK",t:GetAttribute("UsingR15SupportIK"),
    "Scale",t:GetAttribute("HK416ModelScale"),
    "Yaw",t:GetAttribute("GripYawDegrees"))
```

**이 수치는 Studio에서만 알 수 있습니다.** `facing`이 0 미만이면 `R15_GRIP_YAW_DEGREES`를 원래 0으로 되돌려 반대 방향을 시험하세요. 전방을 향해도 손/어깨 위치가 어긋나면 다음 단계에서 캐릭터 체형에 맞춘 Tool Grip 위치 및 IK 타깃 좌표를 조정해야 합니다.

메시 에셋들은 `ServerStorage`에 로컬로 저장되며 GitHub에는 업로드되지 않습니다. Rojo 스크립트 변경만으로 Studio의 모델을 삭제하거나 재임포트할 필요는 없습니다.

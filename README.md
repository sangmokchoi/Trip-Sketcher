# Trip Sketcher

<img
  src="https://github.com/user-attachments/assets/51efcc08-2277-4b40-a820-82b3d60ecfd3"
  width="50%"
/>
</br>

## 00. 개요

- **개발 기간:** 2023.8 - 2023.10

- **Github:** [https://github.com/sangmokchoi/Trip-Sketcher](https://github.com/sangmokchoi/Trip-Sketcher)

- **App Store:** [<Trip Sketcher> 다운로드 바로가기](https://apps.apple.com/us/app/trip-sketcher/id6464154800)

- 기술 구조 요약
  - **UI:** `UIKit`, `Storyboard`
  - **Communication:** `Confluence`
  - **Architecture**: `MVC`
  - **Data Storage**: `Realm DB`
  - **Library/Framework:**
      - **Firebase**
      `Cloud Functions`
      - **Google**
      `Analytics`
</br>

## 01. Trip Sketcher 소개 및 기능


<aside>

몇 번의 터치만으로 여행 일정을 한 눈에!
여행 일정을 지도에 쉽고 빠르게 그려내는 App, Trip Sketcher

여행 계획을 무난하고 효율적으로 관리할 수 있는 기회를 놓치지 마세요.
Trip Sketcher를 다운로드해서 스트레스 없고 효율적인 일정 관리의 여정을 시작하세요.


</aside>

</br>


## 02. 구현 사항

<table>
  <tr>
    <td align="center"><b>2.1. 편리한 일정 관리</b><br /><br /><img src="https://github.com/sangmokchoi/Trip-Sketcher/assets/63656142/26bfdae5-7c1f-48a8-827b-4b4f4ac2cf28" width="378"/></td>
    <td>
    <p>
직관적이고 쉽게 이해할 수 있는 인터페이스를 통해 일정 작성 및 편집을 간편하게 만들어줍니다.
여행 일정을 쉽게 만들고 편집하며, 번거로운 계획 작성에서 벗어날 수 있습니다.
      </p>
   </td>
  </tr>
  <tr>
    <td align="center"><b>2.2. 지도에 한 눈에 나타내는 일정</b><br /><br /><img src="https://github.com/sangmokchoi/Trip-Sketcher/assets/63656142/9312150f-60b7-41f1-8fbe-16bf86e7ebe4" width="378"/></td>
    <td>
      <p>
일정에 위치를 추가하면, 여정을 간편히 시각화할 수 있습니다.
그림을 그리듯이 지도에 일정을 쉽게 그려내 날짜별 일정을 쉽게 살펴보세요
      </p>
    </td>
  </tr>
  <tr>
    <td align="center"><b>2.3. 아이폰 캘린더 통합</b><br /><br /><img src="https://github.com/sangmokchoi/Trip-Sketcher/assets/63656142/c08f1fb0-bc1d-40af-b3d3-c95ff03bd750" width="378"/></td>
    <td>
    <p>
Trip Sketcher는 아이폰 캘린더와 통합되어 일정을 통합적으로 관리합니다.
캘린더 기능을 활용해 더욱 간편하면서도, 체계적으로 계획해보세요.
      </p>
    </td>

  </tr>
  <tr>
    <td align="center"><b>2.4. 예산 관리까지 한 번에</b><br /><br /><img src="https://github.com/sangmokchoi/Trip-Sketcher/assets/63656142/13d3f3f1-956f-4f63-a41b-1473e789c15b" width="378"/></td>
    <td>
<p>
여행 예산이 제한적인가요? Trip Sketcher는 예상 비용을 기록하고 관리할 수 있게 해줍니다.
새로운 경험을 즐기는 동안 지갑도 간편히 관리해보세요.
      </p>
</td>
  <tr>
    <td align="center"><b>2.5. 내보내기를 이용한 일정 공유</b><br /><br /><img src="https://github.com/sangmokchoi/Trip-Sketcher/assets/63656142/d3ad1c2a-7f0d-4ac6-8f85-d2296b020f73" width="378"/></td>
    <td>
    <p>
여행을 다른 사람들에게 공유해야 하나요?
내보내기 기능을 통해서 친구나 가족에게 상세한 일정을 공유해보세요
      </p>
    </td>

  </tr>
</table>



</br>

## 03. **기술적 의사결정**


### 3.1. EventKit
EventKit을 사용하여 iOS의 달력과 연동한 일정 관리가 가능하게끔 구현했습니다.

그래서 Trip Sketcher를 이용해서 생성한 일정은 타 캘린더 앱에서도 연동되며, 다양한 캘린더 태그 색상을 지원하기 때문에 다른 캘린더 앱에서도 해당 일정의 태그 색상은 눈에 잘 띕니다.

### 3.2. Localization
글로벌 유저를 타겟으로 제작한 앱이기에 한국어 지원뿐만 아니라 다국어 지원을 추가했습니다. 기본적으로 영어를 지원하며, 추후 이용자가 점차 늘어난다면, 다른 언어 파일을 추가할 예정입니다.

한 번 localization 작업을 해두면, 다른 언어들을 적용할 때도 많은 시간이 소요되지 않기에 시간을 들여서 꼼꼼히 작업했습니다.

디바이스 언어 설정에 따라서 한국어, 영어를 지원합니다.

### 3.3. 인앱 구매
여행 일정 생성 개수는 무료 버전에서 1개, 유료 버전에서 무제한입니다.

인앱 구매 후 구매 내역을 디바이스에 저장하며, 앱을 새로 설치하더라도 구매 내역 복원을 통해 이전 구매 내용을 그대로 복원할 수 있습니다.

### 3.4. CocoaPods
오픈소스 라이센스 고지를 위해 `AcknowList` 라이브러리를 사용했습니다. dependency 관리를 위해 CocoaPods을 사용했습니다.


## 04. **Trouble Shooting**


### 4.1. 구매내역 저장
#### 문제점
구매내역 복원을 통해서 구매내역을 확인하는 것까지는 구현하였으나, 앱에 재차 진입할 때는 다시 구매내역을 복원해야 하는 문제가 있었습니다.

디바이스에 구매 내역을 저장할 필요가 있었고, 그동안 사용한 UserDefaults를 사용하기에는 데이터 구조가 적합하지 않았습니다.

#### 해결방안
그래서 MongoDB 기반의 realm 데이터베이스를 적용해서 구매내역 복원 시, 구매내역 데이터를 디바이스에 저장했습니다. 이를 통해 유저가 재진입할때에도 구매 여부를 확인하고, 그에 맞춰서 추가 여행 일정 생성 여부를 결정할 수 있었습니다.

### 4.2. 내보내기
혼자 여행을 하는 경우도 있지만, 함께 여행하는 경우도 워낙 많다보니 생성한 여행 일정을 다른 사람과 공유하는 기능이 필수였습니다. 그래서 내보내기 기능을 구현하기로 결정했으며, 다양한 방법을 고민했습니다.

처음 시도한 방법은 전체 화면 스크롤 캡처였습니다.

웹 브라우저에서 화면을 캡처하는 경우 상하로 페이지가 긴 경우에 스크롤 캡처를 자주 이용하는 편이었기에 앱에서도 해당 기능을 구현하려 했습니다.

#### 문제점
그러나, 검은 화면이 캡처되거나, 원하는 길이만큼 캡처가 되지 않았고, 문제를 해결하지 못하는 시간이 길어져 다른 방향으로 선회했습니다.

#### 해결방안
결과적으로는 스크롤뷰의 길이를 계산해서 스크린샷을 나눠서 찍은 뒤, 사진들을 이어붙이는 방식으로 만들었습니다.

### 4.3. 일정별 소요 비용 기록
생성한 여행 일정 내에서 세부적인 일정들을 생성하게 되면, 세부 일정별로 얼마의 비용을 사용했는지 또는 사용할 예정인지를 기록할 수 있는 비용 기록 기능이 있습니다.

#### 문제점
문제는 해당 기능을 위해 UI 구현 중, 비용을 기록하기 위해 숫자 입력 키보드가 나타날 때 발생했습니다. 디바이스의 하단부에 위치한 세부 일정에 비용을 입력하고 하는 경우, 숫자가 입력되는 것이 실시간으로 보여야 할 텍스트필드가 키보드에 가려져 버리는 현상이 나타났습니다.

#### 해결방안
그래서 텍스트필드를 클릭했을때, 텍스트필드의 Y 좌표가 키보드 높이보다 작은 경우에는 그만큼의 값을 view 전체가 위로 움직이게끔 설정했습니다.
추가적으로 텍스트필드 높이만큼 view 전체를 더 위로 가게끔 설정하여 키보드가 나타남과 함께 텍스트 필드가 키보드 바로 위에 오게끔 설정했습니다.

</br>

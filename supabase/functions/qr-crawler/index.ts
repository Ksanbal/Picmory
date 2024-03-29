import { DOMParser } from 'https://deno.land/x/deno_dom/deno-dom-wasm.ts';

/// 모노맨션 다운로드 링크
function monomansion(document: any) {
  const aList = document.querySelectorAll('a')
  
  // https://monomansion.net/api/download.php?qrcode=Y8X3FY21ePx9NvE2fC&type=P
  // ./download.php?qrcode=Y8X3FY21ePx9NvE2fC&type=P
  // 사진 다운로드 링크
  const photoHref = aList[0].getAttribute('href')
  const photo = `https://monomansion.net/api/${photoHref.split('./')[1]}`
  
  // 영상 다운로드 링크
  const videoHref = aList[1].getAttribute('href')
  const video = `https://monomansion.net/api/${videoHref.split('./')[1]}`

  return [ photo, video ];
}

/// 호스트 목록
const hosts = {
  /// 모노맨션
  "monomansion.net": monomansion,
  /// 포토랩+
  "3.37.14.138": null,
  /// 하루필름
  "haru8.mx2.co.kr": null,
  /// 포토 시그니처
  "photoqr2.kr": null,
  /// 플랜비 스튜디오
  "15.165.73.8": null,
  /// 플레이 인 더 박스
  "playintheboxphoto.com": null,
  /// 시현하다
  "frameoffical.cafe24.com": null,
  /// 비비드 뮤지엄
  "vividmuseum.co.kr": null,
  /// 인생네컷
  "l4c01.lifejuin.biz": null,
}

const brands = {
  /// 모노맨션
  "monomansion.net": "monomansion",
  /// 포토랩+
  "3.37.14.138": "photo_lab_plus",
  /// 하루필름
  "haru8.mx2.co.kr": "harufilm",
  /// 포토 시그니처
  "photoqr2.kr": "photo_signature",
  /// 플랜비 스튜디오
  "15.165.73.8": "plan_b_studio",
  /// 플레이 인 더 박스
  "playintheboxphoto.com": "play_in_the_box",
  /// 시현하다
  "frameoffical.cafe24.com": "sihyunhada",
  /// 비비드 뮤지엄
  "vividmuseum.co.kr": "vivid_museum",
  /// 인생네컷
  "l4c01.lifejuin.biz": "life_four_cut",
}

console.log("Hello from Functions!")

Deno.serve(async (req: Request) => {
  try {
    const { url } = await req.json()

    // url 파라미터가 없을 경우
    if (url === null) {
      return new Response(
        JSON.stringify({
          "message": "url 파라미터가 없습니다"
        }), 
        { 
          status: 400, 
          headers: { "Content-Type": "application/json" }, 
        }
      )
    }
    
    // 호스트로 브랜드 구분 및 브랜드별 함수 호출
    const reqHost = url?.split('/')[2]
    const brand = brands[reqHost]
    const brandFunc = hosts[reqHost];

    if (brandFunc === undefined || brandFunc === null) {
      return new Response(
        JSON.stringify({
          "message": "아직 지원하지 않는 브랜드입니다."
        }),
        { 
          status: 400, 
          headers: { "Content-Type": "application/json" }, 
        }
      )
    } 

    // // html 요청
    // const res = await fetch(url)
    // const html = await res.text()
    // const document: any = new DOMParser().parseFromString(html, 'text/html')

    // const [photo, video] = hosts[reqHost](document);

    return new Response(
      // JSON.stringify({
      //   brand,
      //   photo,
      //   video,
      // }),
      // 테스트용으로 고정으로 반환
      JSON.stringify({
        brand: "테스트",
        photo: "https://krrnuzfgncscifoykcsf.supabase.co/storage/v1/object/public/picmory/users/ed2e9572-f9af-4fb6-acdd-d453becf227d/memories/1706758953576/image_picker_82907A66-282F-4F54-8C8C-EF1688530243-6432-0000017E655E41AE.jpg?t=2024-02-01T10%3A37%3A46.604Z",
        video: "https://krrnuzfgncscifoykcsf.supabase.co/storage/v1/object/public/picmory/users/ed2e9572-f9af-4fb6-acdd-d453becf227d/memories/1706758953576/image_picker_CDB523B5-C060-409F-AA5A-5260EB9C19C7-6432-0000017E6D3B8F5Ftrim.F52BBABE-B66F-4A94-B02B-FF9A4E65E516.MOV?t=2024-02-01T10%3A37%3A54.591Z",        
      }),
      { headers: { "Content-Type": "application/json" } },
    )
  } catch (error) {
    console.error(error)
    return new Response(
      JSON.stringify({
        "message": "오류가 발생하였습니다. 다시 시도해주세요."
      }), 
      { status: 400 }
    )
  }
})

/* To invoke locally:

  1. Run `supabase start` (see: https://supabase.com/docs/reference/cli/supabase-start)
  2. Make an HTTP request:

  curl -i --location --request POST 'http://127.0.0.1:54321/functions/v1/qr-crawler' \
    --header 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0' \
    --header 'Content-Type: application/json' \
    --data '{"name":"Functions"}'

*/

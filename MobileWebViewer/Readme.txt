MobileWebViewerセットアップ

サーバーに配置、docnext-server/war等

docnext.js内の
var host = "localhost:8888";
を適切な値に変更


閲覧

閲覧はMobileWebViewerにあるindex.htmlにidを渡す
http://localhost:8888/MobileWebViewer/index.html?id=1等

パラメータ一覧
id = コンテンツのid
page = 開くページ（何も指定してない場合は1ページ目
returnURL = メニューから戻るを押した時にジャンプするURL

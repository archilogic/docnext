Web版セットアップ
gitでソースコードを入手

git clone git@git.archilogic.jp:docnext.git [作成するディレクトリ名]
git checkout square-texture
上記の[作成するディレクトリ名]/web-client/web-clientがWeb版のプロジェクトです
ビルド

プロジェクトの中にある～.sampleファイルをコピーして、
～.sampleを.sampleを抜いた～だけに変更
（.project.sampleから.project.sampleと.projectを生成

FlushBuilder等で読み込んでビルド

ビルドして生成されたファイルを全てサーバー側に置く
（DocumentRootに指定されているdocnext-server/warに置いてます


閲覧

閲覧はサーバー起動後ビルドしたファイルを置いた場所にViewer.htmlがあるのでidを渡す
idが1のドキュメントを閲覧する場合下記のようなURLになります
http://[Web版のファイルを置いたところ、ドメインがlocalhost、tomcatでdocnextと言うDocument名ならここは(localhost/docnext)]/Viewer.html?id=1
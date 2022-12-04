# 概要
私、ととが製作した学習教材の一部です。  

これからChainlinkを活用したDynamicNFTスマートコントラクトを学習される方々向けの学習コースで使用したソースコードを無料提供します。  
※DApp（分散アプリケーション）やスマートコントラクト開発における知識、技術力向上が主な目的です。私は日本におけるこれらの技術発展を望む者です。

コードの解説については現在動画（現時点では有料）のみで行なっています。もし関心のある方いらっしゃればご覧ください。
  
  

### 注意事項
このGitHubリポジトリにあるソースコードは学習目的のものです。  以下の点は予めご了承の上ご利用ください。
  - ソースコードそのものはコースの受講者か否かに限らず[MITライセンス](https://github.com/toto-1010/dNFT-chainlink-basics/blob/main/LICENSE)のもと、無料提供しますが、そのまま使ったり、切り貼りしたりしてご自身のNFTコントラクトを開発し、Ethereumなどのメインネットワークにデプロイすることは推奨しません。  
  - MITライセンス記載の通り、これを禁止するものではありませんが、「本ソフトウェアの使用またはその他の取引に起因または関連して発生した、いかなるクレーム、損害またはその他の責任についても、著作者または著作権所有者は一切責任を負いません。」 と記載がある通り、利用の際はご自身の責任のもと行なってください。 
  - 特定の銘柄や商品の投資や投機を促すものではありません。  
  - 本GitHubリポジトリから直接Q&Aは受け付けていません。  
  - このリポジトリで提供するソースコード以外、例えばコースの解説動画や資料、NFT画像、その他の著作権をはじめとする全ての権利は私、「とと」が有しています。  
  
  

### 解説動画とソースコードのリンク

#### セクション3 時間で変わるdNFT開発
- ソースコード
  - [TimeGrowStagedNFT.sol](https://github.com/toto-1010/dNFT-chainlink-basics/tree/main/contracts/completeCode/TimeGrowStagedNFT.sol "TimeGrowStagedNFT.sol")  
- 【参考】トランザクション
  - [Etherscan transaction](https://goerli.etherscan.io/address/0x23490B2e8003Df61741D71f749bF41CDaA3B2c30 "TimeGrowStagedNFT transactions")  
- 【参考】NFT(OpenSea)
  - [テスト用OpenSea](https://testnets.opensea.io/collection/timegrowstagednft-v2 "TimeGrowStagedNFT NFT")


#### セクション4 指定条件で変わるdNFT開発
- ソースコード
  - [EventGrowStagedNFT.sol](https://github.com/toto-1010/dNFT-chainlink-basics/tree/main/contracts/completeCode/EventGrowStagedNFT.sol "EventGrowStagedNFT.sol")  
- 【参考】トランザクション
  - [Etherscan transaction](https://goerli.etherscan.io/address/0x9a2a77ea65bd17e699a1f754b778dc6c8c763381 "EventGrowStagedNFT transactions")  
- 【参考】NFT(OpenSea)
  - [テスト用OpenSea](https://testnets.opensea.io/collection/eventgrowstagednft "EventGrowStagedNFT NFT")


#### セクション5 Chainlink Any APIとAutomationを連携させた天気情報の自動取得
- ソースコード1
  - [AccuweatherConsumer.sol](https://github.com/toto-1010/dNFT-chainlink-basics/tree/main/contracts/completeCode/AccuweatherConsumer.sol "AccuweatherConsumer.sol")  
- ソースコード2
  - [AutoWeatherInfo.sol](https://github.com/toto-1010/dNFT-chainlink-basics/tree/main/contracts/completeCode/AutoWeatherInfo.sol "AutoWeatherInfo.sol")  
- 【参考】トランザクション
  - [Etherscan transaction](https://goerli.etherscan.io/address/0x901BBb1F0868F67B1c927a97fF158f03c143a0E8 "AutoWeatherInfo transactions")  


#### セクション6 DynamicWeatherNFTコントラクト〜定期更新される天気情報metadata〜
- ソースコード
  - [DynamicWeatherNFT.sol](https://github.com/toto-1010/dNFT-chainlink-basics/tree/main/contracts/completeCode/DynamicWeatherNFT.sol "DynamicWeatherNFT.sol")  
- 【参考】トランザクション
  - [Etherscan transaction](https://goerli.etherscan.io/address/0x9FF96Cf393725A85cf3b11A209973779B21CE1b2 "DynamicWeatherNFT transactions")  
- 【参考】NFT(OpenSea)
  - [テスト用OpenSea](https://testnets.opensea.io/collection/dynamicweathernft-dj0r6qrnqa "DynamicWeatherNFT NFT")

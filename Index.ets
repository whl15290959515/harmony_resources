import { CommonBar } from './comm/CommonBar'
import { CommonSearchBar } from './comm/CommonSearchBar'
import { CouponComponent } from './component/CouponComponent'
import { SpecialColumn } from './component/SpecialColumn'
import { WaterFlowGoods } from './component/WaterFlowGoods'
import { Classification } from './component/Classification'
import CategoryProductPage from './component/MallCategoryPage'
import { cloudDatabase } from '@kit.CloudFoundationKit';
import { home_new_people_coupon } from './clouddb/home_new_people_coupon'
import { coupon_info } from './clouddb/coupon_info'
import { homeNewPeopleCoupon } from './entity/homeNewPeopleCoupon'
import { hilog } from '@kit.PerformanceAnalysisKit';
import { couponInfo } from './entity/couponInfo'
import { split_layout } from './clouddb/split_layout'
import { home_activity_setting } from './clouddb/home_activity_setting'
import { home_banner } from './clouddb/home_banner'
import { Callback, emitter} from '@kit.BasicServicesKit';
import { SplitLayout } from './component/SplitLayout'
import { SplitLayoutModel } from './entity/SplitLayoutModel'
import { HomeActivitySetting } from './entity/HomeActivitySetting'
import { HomePoster } from './entity/HomePoster'
import { home_poster } from './clouddb/home_poster'
import { HomeGoodCenter } from './entity/HomeGoodCenter'
import { home_good_center } from './clouddb/home_good_center'
import { HomeBanner } from './entity/HomeBanner'
import { HomeBannerPage } from './component/HomeBannerPage'
import { home_product_list } from './clouddb/home_product_list'
import { HomeProductList } from './entity/HomeProductList'
import { CartList } from './component/CartList'
import { Mine } from './component/Mine'
import { StorageUtils } from './utils/StorageUtils'
import { User } from './entity/User'
import { UserInfo } from './entity/UserInfo'
import { user_info } from './clouddb/user_info'
import { CommonTopBar } from './widget/CommonTopBar'
import { cart_product_list } from './clouddb/cart_product_list'
import { scanCore, scanBarcode } from '@kit.ScanKit';
import { BusinessError } from '@kit.BasicServicesKit';
import showToast from './utils/ToastUtils'
import { router } from '@kit.ArkUI'
import { ProductDetailModel } from './model/ProductDetailModel'
import { user } from './clouddb/user'

let databaseZone = cloudDatabase.zone('default');

@Entry
@Component
struct Index {
  private controller: TabsController = new TabsController();
  @State currentIndex: number = 0
  @State isCheck_Index_One:boolean=true
  @State LocationName:string='未选择区域'
  private scrollerForScroll: Scroller = new Scroller()
  @State home_new_people_coupon:homeNewPeopleCoupon|null=null//新用户
  @State couponList:couponInfo[]=[]//新用户优惠券列表
  @State splitList:SplitLayoutModel[]=[]//金刚区
  @State homeActivity:HomeActivitySetting[]=[]//首页活动配置
  @State homePoster:HomePoster[]=[]//海报
  @State homeGoodCenter:HomeGoodCenter[]=[]//商品活动入口
  @State flag: boolean = false;//加载tag
  @State homeBanner:HomeBanner[]=[]//banner数据
  @State homeProduct:HomeProductList[]=[]//商品流数据
  @State pos_check:number=0
  @State pos_check_id:number=0
  @Provide user: User|null=null
  @Provide userInfo:UserInfo|null=null
  @State badgeCount:number=0
  @State listRefresh:boolean=false


  @Builder tabBuilder(title: string, targetIndex: number, selectedImg: Resource, normalImg: Resource) {
    Column() {
      if (targetIndex==2){
        Badge({
          count: this.badgeCount,
          style: { badgeSize: 14, badgeColor: '#FA2A2D'},
          position: BadgePosition.RightTop,
        })
        {
          Image(this.currentIndex === targetIndex ? selectedImg : normalImg)
            .width(30)
            .height(30)
        }
      }else {
        Image(this.currentIndex === targetIndex ? selectedImg : normalImg)
          .width(this.isCheck_Index_One&&targetIndex===0?50:25)
          .height(this.isCheck_Index_One&&targetIndex===0?50:25)
          .borderRadius(this.isCheck_Index_One&&targetIndex===0?25:0)
      }
      Text(title)
        .fontSize(14)
        .margin({top:5})
        .fontWeight(this.currentIndex === targetIndex ?FontWeight.Bold:FontWeight.Normal)
        .fontColor(this.currentIndex === targetIndex ? '#fff65753' : '#6B6B6B')
    }
    .width('100%')
    .height(50)
    .justifyContent(FlexAlign.Center)
  }

  async onPageShow(): Promise<void> {
    const params = this.getUIContext().getRouter().getParams() as User;

    if (params) {
      const info: User = params;
      if (info!=null) {
        this.controller.changeIndex(3);
        this.user=info
        let databaseZone = cloudDatabase.zone('default');
        let condition = new cloudDatabase.DatabaseQuery(user_info);
        condition.equalTo("user_id",info.user_id)
        let listData = await databaseZone.query(condition);
        let json = JSON.stringify(listData)
        let data2:UserInfo[]= JSON.parse(json)
        this.userInfo=data2[0]
        hilog.error(0x0000, 'testTag', `Failed to query data, code: ${data2}`);
      }
    }
  }

  async aboutToAppear() {

    const  userInfo= await StorageUtils.getAll('user')
    if (userInfo!=null&&userInfo!='') {
      this.user=JSON.parse(userInfo)
      let databaseZone = cloudDatabase.zone('default');
      let condition = new cloudDatabase.DatabaseQuery(cart_product_list);
      condition.equalTo("user_id",this.user?.user_id)
      let listData = await databaseZone.query(condition);
      this.badgeCount=listData.length
    }else {
      this.badgeCount=0
    }

    let innerEvent: emitter.InnerEvent = {
      eventId: 1011
    };
    let callback: Callback<emitter.EventData> = async (eventData: emitter.EventData) => {
      console.info(`eventData: ${JSON.stringify(eventData)}`);
      let databaseZone = cloudDatabase.zone('default');
      let condition = new cloudDatabase.DatabaseQuery(cart_product_list);
      condition.equalTo("user_id",this.user?.user_id)
      let listData = await databaseZone.query(condition);
      this.badgeCount=listData.length
      hilog.info(0x0000, 'testTag', `Succeeded in upserting data, result: ${listData}`);
    }
    emitter.on(innerEvent, callback);


    let innerEvent1: emitter.InnerEvent = {
      eventId: 1012
    };

    let callback1: Callback<emitter.EventData> = async (eventData: emitter.EventData) => {
      this.listRefresh=true
      let databaseZone = cloudDatabase.zone('default');
      let condition = new cloudDatabase.DatabaseQuery(cart_product_list);
      condition.equalTo("user_id",this.user?.user_id)
      let listData = await databaseZone.query(condition);
      this.badgeCount=listData.length
    }
    emitter.on(innerEvent1, callback1);




    let innerEvent2: emitter.InnerEvent = {
      eventId: 2001
    };
    let callback2: Callback<emitter.EventData> = async (eventData: emitter.EventData) => {
      console.info(`eventData: ${JSON.stringify(eventData)}`);
      const value = await StorageUtils.getAll('user');
      if (value != "") {
        this.user = JSON.parse(value)
      }else {
        this.userInfo=null
        this.user=null
      }
    }
    emitter.on(innerEvent2, callback2);




    const value = await StorageUtils.getAll("locationName")
    if (value != "") {
      this.LocationName = value;
    }
    try {
      let condition = new cloudDatabase.DatabaseQuery(home_new_people_coupon);
      let condition1 = new cloudDatabase.DatabaseQuery(coupon_info);
      let condition2 = new cloudDatabase.DatabaseQuery(split_layout);
      let condition3 = new cloudDatabase.DatabaseQuery(home_activity_setting);
      let poster = new cloudDatabase.DatabaseQuery(home_poster);
      let home_good = new cloudDatabase.DatabaseQuery(home_good_center);
      let home_banner_condition = new cloudDatabase.DatabaseQuery(home_banner);
      let home_product=new cloudDatabase.DatabaseQuery(home_product_list);




      let listData = await databaseZone.query(condition);
      let json = JSON.stringify(listData)
      let data:homeNewPeopleCoupon= JSON.parse(json)
      this.home_new_people_coupon=data;
      let listData1 = await databaseZone.query(condition1);
      condition1.equalTo("home_coupon_activity_id",data.home_coupon_activity_id)
      let json1 = JSON.stringify(listData1)
      let data1:couponInfo[]= JSON.parse(json1)
      this.couponList=data1
      hilog.info(0x0000, 'testTag', `Succeeded in querying data, result: ${this.couponList}`);



      let listData2 = await databaseZone.query(condition2);
      let json2 = JSON.stringify(listData2)
      let data2:SplitLayoutModel[]= JSON.parse(json2)
      this.splitList=data2
      hilog.error(0x0000, 'testTag', `Failed to query data, code: ${this.splitList}`);

      let listData3 = await databaseZone.query(condition3);
      let json3 = JSON.stringify(listData3)
      let data3:HomeActivitySetting[]= JSON.parse(json3)
      this.homeActivity=data3
      hilog.error(0x0000, 'testTag', `Failed to query data, code: ${this.homeActivity}`);
      let list5 = await databaseZone.query(home_good);
      home_good.equalTo("good_left_id",data3[0].good_left_id);
      let json5 = JSON.stringify(list5)
      let data5:HomeGoodCenter[]= JSON.parse(json5)
      this.homeGoodCenter=data5
      hilog.error(0x0000, 'testTag', `Failed to query data, code: ${this.homeGoodCenter}`);


      let listPoster = await databaseZone.query(poster);
      let json4 = JSON.stringify(listPoster)
      let data4:HomePoster[]= JSON.parse(json4)
      this.homePoster=data4
      hilog.error(0x0000, 'testTag', `Failed to query data, code: ${this.homePoster}`);





      let list6 = await databaseZone.query(home_banner_condition);
      let json6 = JSON.stringify(list6)
      let data6:HomeBanner[]= JSON.parse(json6)
      this.homeBanner=data6
      hilog.error(0x0000, 'testTag', `Failed to query data, code: ${this.homeBanner}`);


      let list7 = await databaseZone.query(home_product);
      let json7 = JSON.stringify(list7)
      let data7:HomeProductList[]= JSON.parse(json7)
      this.homeProduct=data7
      hilog.error(0x0000, 'testTag', `Failed to query data, code: ${this.homeProduct}`);


      this.flag=true
    }catch (err) {
      hilog.error(0x0000, 'testTag', `Failed to query data, code: ${this.homeProduct}`);
    }
  }



  build() {

    Column() {
      Tabs({barPosition:BarPosition.End,controller:this.controller}) {
        TabContent() {
          if (this.flag){
            Column(){
              Scroll(this.scrollerForScroll){
                Column(){
                  CommonBar({locationName:this.LocationName,onBtClick:()=>{
                    if (this.user!=null) {
                      router.push({
                        url: "pages/component/QRCodePage"
                      })
                    }else {
                      showToast("请先登录")
                    }

                  }})
                  CommonSearchBar({onSearchClick:()=>{
                      let options: scanBarcode.ScanOptions = {
                        scanTypes: [scanCore.ScanType.ALL],
                        enableMultiMode: true,
                        enableAlbum: true
                      };
                      try {
                        scanBarcode.startScanForResult(getContext(this), options).then((result: scanBarcode.ScanResult) => {
                          hilog.info(0x0001, '[Scan CPSample]', `Succeeded in getting ScanResult by promise with options, result is ${JSON.stringify(result)}`);
                          if (result.originalValue!=null) {
                            let product: ProductDetailModel = {
                              id: Number(result.originalValue)
                            };
                            router.pushUrl({
                              url: 'pages/component/ProductDetailsPage',
                              params: product
                            }, (err) => {
                              if (err) {
                                console.error(`Invoke pushUrl failed, code is ${err.code}, message is ${err.message}`);
                                return;
                              }
                              console.info('Invoke pushUrl succeeded.');
                            });
                          }

                        }).catch((error: BusinessError) => {
                          hilog.error(0x0001, '[Scan CPSample]',
                            `Failed to get ScanResult by promise with options. Code:${error.code}, message: ${error.message}`);
                        });
                      } catch (error) {
                        hilog.error(0x0001, '[Scan CPSample]',
                          `Failed to start the scanning service. Code:${error.code}, message: ${error.message}`);
                      }
                  }})
                  HomeBannerPage({bannerList:this.homeBanner})
                  CouponComponent({home_activity:this.home_new_people_coupon,couponList:this.couponList,callback: async ()=>{
                    let users=new user()
                    users.id=this.user!.id
                    users.user_id=this.user!.user_id
                    users.user_name=this.user!.user_name
                    users.psw=this.user!.psw
                    users.is_vip=false
                    users.user_code=this.user!.user_code
                    users.is_log_off=this.user!.is_vip
                    let num = await databaseZone.upsert(users);
                    StorageUtils.set("user",JSON.stringify(users))

                    if (num>0) {

                        let condition3 = new cloudDatabase.DatabaseQuery(user);
                        condition3.equalTo("user_name",this.user?.user_name).and().equalTo("psw",this.user?.psw)
                        let listData3 = await databaseZone.query(condition3);
                        let json3 = JSON.stringify(listData3)
                        let data3:User[]= JSON.parse(json3)
                        this.user=data3[0]

                    }
                  },user:this.user})
                    .visibility(this.user?.is_vip?Visibility.Visible:Visibility.None)

                  if (this.homeActivity[0].split_layout_status) {
                    SplitLayout({listData:this.splitList,onItemClick:(pos,id)=>{
                      this.controller.changeIndex(1);
                      this.pos_check=pos
                      this.pos_check_id=id
                    }})
                  }

                    Image($r('app.media.recycle_banner'))
                      .width("95%")
                      .margin({top:10})
                      .borderRadius(20)
                      .objectFit(ImageFit.Cover)
                      .onClick(()=>{
                        //根据router跳转
                        router.pushUrl({url:'pages/recycle/home/RecycleHomePage'})
                      })

                  SpecialColumn({goodInfo:this.homeGoodCenter})
                    .visibility(Visibility.None)
                  WaterFlowGoods({goodsList:this.homeProduct})
                }

              }
              .height('100%')
              .scrollable(ScrollDirection.Vertical)

            }
            .linearGradient({
              angle:180,
              colors: [[0xff0000, 0], [0xff6666, 0.2], [0xffffff, 1]]
            })
            .height('100%')
          }




        }
        .tabBar(this.tabBuilder(this.currentIndex==0?"":"首页",0,$r("app.media.e_logo"),$r('app.media.index1_not_check')))



        TabContent() {
          Scroll(){
            Column(){
              CommonTopBar({ title: "分类", alpha: 0, titleAlignment: TextAlign.Center ,backButton:false})
              Classification({selectedIndex:this.pos_check,onItemClick:(pos,child_id)=>{
                this.pos_check=pos
                this.pos_check_id=child_id
              }})
              CategoryProductPage({topListItemChildId:this.pos_check_id})
            }
            .height('100%')
            .justifyContent(FlexAlign.Start)
          }
        }
        .tabBar(this.tabBuilder("分类",1,$r('app.media.index2_check'),$r('app.media.index2_not_check')))
        TabContent() {
          Scroll(){
            Column(){
              CartList({currentIndex:this.currentIndex,listRefresh:this.listRefresh})
            }
          }
        }
        .tabBar(this.tabBuilder("购物车",2,$r('app.media.index3_check'),$r('app.media.index3_not_check')))
        TabContent() {
          Column(){
            Mine({currentIndex:this.currentIndex})
          }
        }
        .tabBar(this.tabBuilder("我的",3,$r('app.media.index4_check'),$r('app.media.index4_not_check')))

      }
      .onChange((index: number) => {
        this.currentIndex = index
        if (index==0) {
          this.isCheck_Index_One=true
        }else {
          this.isCheck_Index_One=false
        }
      })
    }
    .backgroundColor(Color.White)
    .height('100%')
    .width('100%')
  }


}


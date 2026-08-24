Page({
  data: {
    status: 0,
    imgSrc: "/images/1.png",
    btnText: "打开笼子",
    showTip: false
  },
  handleBtnClick(){
    if(this.data.status === 0){
      this.setData({
        status:1,
        imgSrc:"/images/2.png",
        btnText:"点击追逐逮捕",
        showTip:true
      })
    }else{
      this.setData({
        status:0,
        imgSrc:"/images/1.png",
        btnText:"打开笼子",
        showTip:false
      })
    }
  }
})

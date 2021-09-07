const { expect } = require("chai");
const { ethers } = require("hardhat");

const DAY_IN_SECONDS = 86400;

describe("ETHPool", function () {

  beforeEach(async function() {
    [this.UserA, this.UserB] = await hre.ethers.getSigners();

    this.ETHPool = await hre.ethers.getContractFactory("ETHPool");
    this.ethpool = await this.ETHPool.deploy();
    await this.ethpool.deployed();
  });

  it("Solution Example: Weighted average amount according to the number of days", async function () {

    await ethers.provider.send("evm_increaseTime", [DAY_IN_SECONDS*1]) 

    await this.ethpool
      .connect(this.UserA)
      .deposit({value: ethers.utils.parseEther("150")});

    await ethers.provider.send("evm_increaseTime", [DAY_IN_SECONDS*2]) 

    await this.ethpool
      .connect(this.UserB)
      .deposit({value: ethers.utils.parseEther("300")});

    await ethers.provider.send("evm_increaseTime", [DAY_IN_SECONDS*2]) 

    await this.ethpool
      .connect(this.UserA)
      .deposit({value: ethers.utils.parseEther("200")});

    await ethers.provider.send("evm_increaseTime", [DAY_IN_SECONDS*2]) 

    await this.ethpool
      .depositRewards({value: ethers.utils.parseEther("60")});


    let balanceUserA =  ethers.utils.formatEther(await this.ethpool.connect(this.UserA).getTotalBalance());
    let balanceUserB =  ethers.utils.formatEther(await this.ethpool.connect(this.UserB).getTotalBalance());   

    expect(parseFloat(balanceUserA)).to.be.closeTo(381.2, 0.01);
    expect(parseFloat(balanceUserB)).to.be.closeTo(328.8, 0.01);    
  });

  it("Challenge - First Example", async function () {
  
    await this.ethpool
      .connect(this.UserA)
      .deposit({value: ethers.utils.parseEther("100")});

      await this.ethpool
      .connect(this.UserB)
      .deposit({value: ethers.utils.parseEther("300")});

      await ethers.provider.send("evm_increaseTime", [DAY_IN_SECONDS*7]) 

      await this.ethpool
      .depositRewards({value: ethers.utils.parseEther("200")});   
      
      let balanceUserA =  ethers.utils.formatEther(await this.ethpool.connect(this.UserA).getTotalBalance());
      let balanceUserB =  ethers.utils.formatEther(await this.ethpool.connect(this.UserB).getTotalBalance());   
      
    expect(parseFloat(balanceUserA)).to.equal(150);
    expect(parseFloat(balanceUserB)).to.equal(450);     
  });

  it("Challenge - Second Example", async function () {
  
    await this.ethpool
      .connect(this.UserA)
      .deposit({value: ethers.utils.parseEther("150")});

      await ethers.provider.send("evm_increaseTime", [DAY_IN_SECONDS*7]) 

      await this.ethpool
      .depositRewards({value: ethers.utils.parseEther("50")});   

      await this.ethpool
      .connect(this.UserB)
      .deposit({value: ethers.utils.parseEther("250")});  
      
      
      await this.ethpool
      .connect(this.UserA)
      .withdraw(ethers.utils.parseEther("200"));

      await this.ethpool
      .connect(this.UserB)
      .withdraw(ethers.utils.parseEther("250"));      
    

      let  balanceUserA =  ethers.utils.formatEther(await this.ethpool.connect(this.UserA).getTotalBalance());
      let balanceUserB =  ethers.utils.formatEther(await this.ethpool.connect(this.UserB).getTotalBalance());   
      
      expect(parseFloat(balanceUserA)).to.equal(0);
      expect(parseFloat(balanceUserB)).to.equal(0);
  });


});

const { expect } = require("chai");

describe("Registrar Instance", function () {
  const domain = "mydomain";
  let registrar;

  let deployer,
    account1,
    account2,
    account3,
    account4,
    account5,
    Registrar,
    Registry;

  beforeEach(async function () {
    [deployer, account1, account2, account3, account4, account5] =
      await ethers.getSigners();

    const registrar = await ethers.getContractFactory("Registrar");
    Registrar = await registrar.deploy(domain, deployer.address);
  });

  describe("It deployes the contract correctly", function () {
    it("Deployment", async function () {
      expect(await Registrar.owner()).to.equal(deployer.address);
    });
  });

  describe("It sets the state variables on deploy", function () {
    it("Sets parent domain", async function () {
      const ownerInfo = await Registrar.ownerInfo();
      expect(await Registrar.parentDomain()).to.equal(domain);
    });

    it("Sets registry contract address to the contract creator", async function () {
      expect(await Registrar.registryContractAddr()).to.equal(deployer.address);
    });

    it("Sets the domain owner to the caller of 'newDomain' function", async function () {
      const ownerInfo = await Registrar.ownerInfo();
      expect(ownerInfo.owner).to.equal(deployer.address);
    });
  });

  describe("Creates a subdomain", function () {
    const subDomainA = "subdomain-a";
    const subDomainB = "subdomain-b";
    const subDomainC = "subdomain-c";

    const blankSet = "_";
    const subDomain = "elon";
    const invalidName = "#1sasd42$$%";
    let subDomainAObj;

    beforeEach(async function () {
      await Registrar.setNewSubdomain(subDomain);
      await Registrar.setNewSubdomain(subDomainA);
      await Registrar.setNewSubdomain(subDomainB);
    });

    it("Reverts when caller is not the owner of the parent domain", async function () {
      await expect(
        Registrar.connect(account3).setNewSubdomain(subDomain)
      ).to.be.revertedWith("Ownable: caller is not the owner");
    });

    it("Creates a new subdomain", async function () {
      subDomainObj = await Registrar.subDomainData(subDomain);
    });

    it("Not yet created subdomains to belong to zero address", async function () {
      const subdomainCObject = await Registrar.subDomainData(subDomainC);
      expect(subdomainCObject.owner).to.equal(ethers.constants.AddressZero);
    });

    it("Subdomain belongs to owner right after cration", async function () {
      const subdomainAObject = await Registrar.subDomainData(subDomainA);
      expect(subdomainAObject.owner).to.equal(deployer.address);
    });

    it("New subdomain gets registered", async function () {
      expect(await Registrar.registered(subDomainA)).to.be.true;
    });

    it("Not yet created subdomains aren't registered", async function () {
      expect(await Registrar.registered(subDomainC)).to.be.false;
    });

    it("New subdomain gets activated", async function () {
      expect(await Registrar.isDomainActive(subDomainA)).to.be.true;
    });

    it("Not yet created subdomains aren't activated", async function () {
      expect(await Registrar.isDomainActive(subDomainC)).to.be.false;
    });

    it("New subdomain gets pushed to domains array", async function () {
      expect(await Registrar.subDomainsList(0)).to.equal(subDomain);
      expect(await Registrar.subDomainsList(1)).to.equal(subDomainA);
      expect(await Registrar.subDomainsList(2)).to.equal(subDomainB);
    });

    it("Not yet created subdomains aren't pushed to domains array", async function () {
      const allSubdomains = await Registrar.getAllSubDomains();
      expect(allSubdomains.length).to.equal(3);
    });

    it("Reverts when unavailable", async function () {
      await expect(Registrar.setNewSubdomain(subDomain)).to.be.rejectedWith(
        "This subdomain already exists!"
      );
    });

    it("Reverts with invalid names", async function () {
      await expect(Registrar.setNewSubdomain(invalidName)).to.be.rejectedWith(
        "This is not a valid domain name!"
      );
    });

    it("Sets every field to blank and gives ownership to parent domain onwer", async function () {
      expect(subDomainObj.owner).to.equal(deployer.address);
      expect(subDomainObj.description).to.equal(blankSet);
      expect(subDomainObj.website).to.equal(blankSet);
      expect(subDomainObj.email).to.equal(blankSet);
      expect(subDomainObj.avatar).to.equal(blankSet);
    });
  });

  describe("Sets owner data", function () {
    const description = "descriptions text";
    const website = "vercel.com";
    const email = "vitalik@eth.com";
    const avatar = "Green Gobblin";
    let ownerData;

    beforeEach(async function () {
      await Registrar.setOwnerData(description, website, email, avatar);
      ownerData = await Registrar.ownerInfo();
    });

    it("Reverts if the caller is not the owner", async function () {
      await expect(
        Registrar.connect(account1).setOwnerData(
          description,
          website,
          email,
          avatar
        )
      ).to.be.revertedWith("Ownable: caller is not the owner");
    });

    it("Sets description", async function () {
      expect(ownerData.description).to.equal(description);
    });
    it("Sets website", async function () {
      expect(ownerData.website).to.equal(website);
    });
    it("Sets email", async function () {
      expect(ownerData.email).to.equal(email);
    });
    it("Sets avatar", async function () {
      expect(ownerData.avatar).to.equal(avatar);
    });
  });

  describe("Change Subdomain Data", function () {
    const ownerSubDomain = "ownersDomain";
    const userSubDomain = "userDomain";

    const subdomain = {
      description: "descriptions text",
      website: "vercel.com",
      email: "vitalik@eth.com",
      avatar: "Green Gobblin",
    };

    const control = {
      description: "Eths Backbone",
      website: "youtube.com",
      email: "gavinwood@eth.com",
      avatar: "Bright Cat",
    };

    beforeEach(async function () {
      await Registrar.setNewSubdomain();
    });
  });

  describe("Transfering a subdomain", function () {
    const subDomainA = "subdomain-a";
    const subDomainB = "subdomain-b";
    const subDomainC = "subdomain-c";

    beforeEach(async function () {
      await Registrar.setNewSubdomain(subDomainA);
      await Registrar.setNewSubdomain(subDomainB);
    });

    it("Reverts if domain doesn't exist", async function () {
      const target = account3.address;
      await expect(
        Registrar.transferSubDomain(subDomainC, target)
      ).to.be.revertedWith("You are not the owner of this sub-domain");
    });

    it("Transfers the domain to another account", async function () {
      const target = account1.address;
      await Registrar.transferSubDomain(subDomainA, target);
      const transferedSubdomain = await Registrar.subDomainData(subDomainA);

      expect(transferedSubdomain.owner).to.equal(target);
    });

    it("Not trasnfered domains stay with the owner", async function () {
      const notTransferedSubdomain = await Registrar.subDomainData(subDomainB);
      expect(notTransferedSubdomain.owner).to.equal(deployer.address);
    });

    it("Owner can no longer transfer a subdomain that is no longer his", async function () {
      const target = account2.address;
      await Registrar.transferSubDomain(subDomainA, target);
      const transferedSubdomain = await Registrar.subDomainData(subDomainA);

      await expect(
        Registrar.transferSubDomain(subDomainA, target)
      ).to.be.revertedWith("You are not the owner of this sub-domain");
    });

    it("New owner have a domain", async function () {});
    it("New owner can transfer", async function () {});
    it("New owner can delete", async function () {});
    it("Transfer resets data", async function () {});
    it("Transfer back to owner deletes", async function () {});
  });
});

const { expect } = require("chai");

describe("Registry", function () {
  let deployer, account1, account2, account3, account4, account5, Registry;

  beforeEach(async function () {
    [deployer, account1, account2, account3, account4, account5] =
      await ethers.getSigners();

    const registry = await ethers.getContractFactory("Registry");
    Registry = await registry.deploy();
  });

  describe("It deployes the contract with correct name and ticket", function () {
    it("Sets owner to deployer", async function () {
      expect(await Registry.owner()).to.equal(deployer.address);
    });

    it("Sets name to Registry", async function () {
      expect(await Registry.name()).to.equal("Registry");
    });

    it("Sets symbol to INU", async function () {
      expect(await Registry.symbol()).to.equal("INU");
    });
  });

  describe("Creates a new domain", function () {
    it("Creates a new domain and creator is the owner", async function () {
      const user1Signer = account1;
      const user1Address = account1.address;
      const user1Domain = "uniswap";

      await Registry.connect(user1Signer).newDomain(user1Domain);
      const userData = await Registry.registry(user1Domain);

      expect(await userData.owner).to.equal(user1Address);
    });

    it("Reverts if domain already exists", async function () {
      const domain = "uniswap";

      await Registry.newDomain(domain);

      await expect(Registry.newDomain(domain)).to.be.revertedWith(
        "This domain is not available"
      );
    });

    it("Reverts with invalid names", async function () {
      const invalidDomain = "#12&*34";
      await expect(Registry.newDomain(invalidDomain)).to.be.revertedWith(
        "This is not a valid domain name!"
      );
    });
  });

  describe("Set primary domains", function () {
    const domain1 = "test-a";
    const domain2 = "test-b";
    const domain3 = "test-c";
    const domain4 = "test-d";

    beforeEach(async function () {
      await Registry.newDomain(domain1);
      await Registry.newDomain(domain2);
      await Registry.newDomain(domain3);

      await Registry.connect(account1).newDomain(domain4);
    });

    it("Sets primary domain", async function () {
      expect(await Registry.primaryDomain(deployer.address)).to.be.equal(
        domain1
      );

      await Registry.setPrimaryDomain(domain2);

      expect(await Registry.primaryDomain(deployer.address)).to.be.equal(
        domain2
      );
    });

    it("Creates multiple domains but only the first is primary by default", async function () {
      expect(await Registry.primaryDomain(deployer.address)).to.equal(domain1);
    });

    it("If address has no domains and receives one, it becomes primary", async function () {
      expect(await Registry.balanceOf(account3.address)).to.be.equal(0);
      expect(await Registry.primaryDomain(account3.address)).to.be.equal("");

      await Registry.transferFrom(deployer.address, account3.address, 0);

      expect(await Registry.balanceOf(account3.address)).to.be.equal(1);
      expect(await Registry.primaryDomain(account3.address)).to.be.equal(
        domain1
      );
    });

    it("Can't set primary domain if caller is not owner", async function () {
      await expect(
        Registry.connect(account2).setPrimaryDomain(domain1)
      ).to.be.revertedWith("You are not the onwer of this domain!");
    });

    it("Can't set primary if domain is already", async function () {
      await expect(Registry.setPrimaryDomain(domain1)).to.be.revertedWith(
        "This is already your primary domain!"
      );
    });
  });

  describe("Transfer domains", function () {
    const domain1 = "test-a";
    const domain2 = "test-b";
    const domain3 = "test-c";
    const domain4 = "test-d";

    beforeEach(async function () {
      await Registry.newDomain(domain1);
      await Registry.newDomain(domain2);
      await Registry.newDomain(domain3);

      await Registry.connect(account1).newDomain(domain4);
    });

    it("Reverts if caller is not owner", async function () {
      await expect(
        Registry.connect(account1).transferFrom(
          deployer.address,
          account3.address,
          0
        )
      ).to.be.revertedWith("ERC721: caller is not token owner or approved");
    });

    it("Updates token to owner", async function () {
      const domain = await Registry.tokenToDomain(0);
      const Pointer = await Registry.registry(domain);
      expect(Pointer.owner).to.be.equal(deployer.address);

      await Registry.transferFrom(deployer.address, account1.address, 0);
      const newPointer = await Registry.registry(domain);

      expect(newPointer.owner).to.be.equal(account1.address);
    });

    it("Cleans your primary domain if you transfer it", async function () {
      expect(await Registry.primaryDomain(deployer.address)).to.be.equal(
        domain1
      );

      await Registry.transferFrom(deployer.address, account1.address, 0);

      expect(await Registry.primaryDomain(deployer.address)).to.be.equal("");
    });
  });
});

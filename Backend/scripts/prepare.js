const { ethers, upgrades } = require("hardhat");

async function main() {
  const proxy = "0xB35277ae23d34FC6cd4CC230C5528db55F8289CB";

  const fqName = "contracts/EscrowUpgradeable.sol:EscrowUpgradeable";
  const EscrowUpgradeable = await ethers.getContractFactory(fqName);

  console.log("⏳ Preparando nueva implementación…");
  const newImpl = await upgrades.prepareUpgrade(proxy, EscrowUpgradeable, {
    kind: "transparent",
  });

  console.log("📌 Nueva implementación preparada en:", newImpl);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

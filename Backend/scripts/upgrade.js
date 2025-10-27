const { ethers, upgrades, artifacts } = require("hardhat");

async function main() {
  const proxy = "0xB35277ae23d34FC6cd4CC230C5528db55F8289CB";

  // Usa el nombre completamente calificado:
  const fqName = "contracts/EscrowUpgradeable.sol:EscrowUpgradeable";
  const EscrowUpgradeable = await ethers.getContractFactory(fqName);

  console.log("⏫ Preparing new implementation…");
  const newImpl = await upgrades.prepareUpgrade(proxy, EscrowUpgradeable, { kind: "transparent" });
  console.log("🔎 Prepared impl at:", newImpl);

  console.log("⏫ Upgrading proxy…");
  await upgrades.upgradeProxy(proxy, EscrowUpgradeable, { kind: "transparent" });

  const afterImpl = await upgrades.erc1967.getImplementationAddress(proxy);
  console.log("✅ Proxy now points to:", afterImpl);
}
main().catch((e)=>{console.error(e);process.exitCode=1;});

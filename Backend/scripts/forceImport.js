const { ethers, upgrades } = require("hardhat");

async function main() {
  const proxy = "0xB35277ae23d34FC6cd4CC230C5528db55F8289CB";
  const EscrowUpgradeable = await ethers.getContractFactory("EscrowUpgradeable");

  await upgrades.forceImport(proxy, EscrowUpgradeable, { kind: "transparent" });
  console.log("✅ Proxy importado al manifest de OpenZeppelin.");
}

main().catch((e) => { console.error(e); process.exitCode = 1; });

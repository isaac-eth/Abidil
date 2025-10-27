const { upgrades } = require("hardhat");

async function main() {
  const proxy = "0xB35277ae23d34FC6cd4CC230C5528db55F8289CB";

  const impl = await upgrades.erc1967.getImplementationAddress(proxy);
  const admin = await upgrades.erc1967.getAdminAddress(proxy);

  console.log("📌 Proxy:", proxy);
  console.log("📌 Implementation:", impl);
  console.log("📌 Proxy Admin:", admin);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

import { writeSolidityVerifier } from "@aztec/bb.js";
import fs from "fs";
import path from "path";

const vkPath = path.resolve("../target/vk");
const outPath = path.resolve("../target/Verifier.sol");

async function generateVerifier() {
  await writeSolidityVerifier(vkPath, outPath);
  console.log(" Verifier.sol generated at", outPath);
}

generateVerifier();

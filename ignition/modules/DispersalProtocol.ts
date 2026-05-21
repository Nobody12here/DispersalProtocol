import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("DispersalModule", (m) => {
  const counter = m.contract("DispersalProtocol");

  m.call(counter, "incBy", [5n]);

  return { counter };
});

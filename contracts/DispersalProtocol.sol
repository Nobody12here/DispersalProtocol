// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract DisperseProtocol {
    using SafeERC20 for IERC20;

    function disperseEther(
        address[] calldata recipients,
        uint256[] calldata values
    ) external payable {
        require(
            recipients.length == values.length,
            "mismatch in recipients and values length !"
        );
        require(recipients.length != 0, "No recipients !");
        require(values.length != 0, "No Values provided !");
        uint256 total = 0;
        for (uint256 i = 0; i < recipients.length; i++) total += values[i];
        require(msg.value >= total, "Low ETH provided than total of values !");
        for (uint256 i = 0; i < recipients.length; i++)
            payable(recipients[i]).transfer(values[i]);
        uint256 balance = address(this).balance;
        if (balance > 0) payable(msg.sender).transfer(balance);
    }

    function disperseToken(
        IERC20 token,
        address[] calldata recipients,
        uint256[] calldata values
    ) external {
        require(
            recipients.length == values.length,
            "mismatch in recipients and values length !"
        );
        require(recipients.length != 0, "No recipients !");
        require(values.length != 0, "No Values provided !");
        uint256 total = 0;
        for (uint256 i = 0; i < recipients.length; i++) total += values[i];
        token.safeTransferFrom(msg.sender, address(this), total);
        for (uint256 i = 0; i < recipients.length; i++)
            token.safeTransfer(recipients[i], values[i]);
    }

    function disperseTokenSimple(
        IERC20 token,
        address[] calldata recipients,
        uint256[] calldata values
    ) external {
        require(
            recipients.length == values.length,
            "mismatch in recipients and values length !"
        );
        require(recipients.length != 0, "No recipients !");
        require(values.length != 0, "No Values provided !");
        for (uint256 i = 0; i < recipients.length; i++)
            token.safeTransferFrom(msg.sender, recipients[i], values[i]);
    }
}

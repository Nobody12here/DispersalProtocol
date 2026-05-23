// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract ClaimableDisperseProtocol is ReentrancyGuard {
    using SafeERC20 for IERC20;

    uint256 public constant MAX_BATCH_SIZE = 500;

    /// @notice ETH claimable balances
    mapping(address => uint256) public ethClaims;

    /// @notice token => user => amount
    mapping(IERC20 => mapping(address => uint256)) public tokenClaims;

    // =============================================================
    //                           EVENTS
    // =============================================================

    event EtherDispersed(
        address indexed sender,
        uint256 recipients,
        uint256 totalAmount
    );

    event TokenDispersed(
        address indexed sender,
        address indexed token,
        uint256 recipients,
        uint256 totalAmount
    );

    event EtherClaimCreated(
        address indexed sender,
        address indexed recipient,
        uint256 amount
    );

    event TokenClaimCreated(
        address indexed sender,
        address indexed token,
        address indexed recipient,
        uint256 amount
    );

    event EtherClaimed(address indexed recipient, uint256 amount);

    event TokenClaimed(
        address indexed recipient,
        address indexed token,
        uint256 amount
    );

    // =============================================================
    //                       DIRECT DISPERSE
    // =============================================================

    function disperseEther(
        address[] calldata recipients,
        uint256[] calldata values
    ) external payable nonReentrant {
        uint256 length = recipients.length;

        require(length == values.length, "Length mismatch");
        require(length > 0, "Empty recipients");
        require(length <= MAX_BATCH_SIZE, "Batch too large");

        uint256 total;

        for (uint256 i; i < length; ) {
            require(recipients[i] != address(0), "Zero address");
            total += values[i];

            unchecked {
                ++i;
            }
        }

        require(msg.value >= total, "Insufficient ETH");

        for (uint256 i; i < length; ) {
            (bool success, ) = payable(recipients[i]).call{value: values[i]}(
                ""
            );

            require(success, "ETH transfer failed");

            unchecked {
                ++i;
            }
        }

        uint256 refund = msg.value - total;

        if (refund > 0) {
            (bool success, ) = payable(msg.sender).call{value: refund}("");
            require(success, "Refund failed");
        }

        emit EtherDispersed(msg.sender, length, total);
    }

    function disperseToken(
        IERC20 token,
        address[] calldata recipients,
        uint256[] calldata values
    ) external nonReentrant {
        uint256 length = recipients.length;

        require(length == values.length, "Length mismatch");
        require(length > 0, "Empty recipients");
        require(length <= MAX_BATCH_SIZE, "Batch too large");

        uint256 total;

        for (uint256 i; i < length; ) {
            require(recipients[i] != address(0), "Zero address");
            total += values[i];

            unchecked {
                ++i;
            }
        }

        token.safeTransferFrom(msg.sender, address(this), total);

        for (uint256 i; i < length; ) {
            token.safeTransfer(recipients[i], values[i]);

            unchecked {
                ++i;
            }
        }

        emit TokenDispersed(msg.sender, address(token), length, total);
    }

    // =============================================================
    //                    CLAIMABLE DISPERSE
    // =============================================================

    /// @notice Create claimable ETH balances instead of direct transfer
    function createEtherClaims(
        address[] calldata recipients,
        uint256[] calldata values
    ) external payable nonReentrant {
        uint256 length = recipients.length;

        require(length == values.length, "Length mismatch");
        require(length > 0, "Empty recipients");
        require(length <= MAX_BATCH_SIZE, "Batch too large");

        uint256 total;

        for (uint256 i; i < length; ) {
            address recipient = recipients[i];
            uint256 amount = values[i];

            require(recipient != address(0), "Zero address");

            total += amount;

            ethClaims[recipient] += amount;

            emit EtherClaimCreated(msg.sender, recipient, amount);

            unchecked {
                ++i;
            }
        }

        require(msg.value >= total, "Insufficient ETH");

        uint256 refund = msg.value - total;

        if (refund > 0) {
            (bool success, ) = payable(msg.sender).call{value: refund}("");
            require(success, "Refund failed");
        }
    }

    /// @notice Create claimable token balances instead of direct transfer
    function createTokenClaims(
        IERC20 token,
        address[] calldata recipients,
        uint256[] calldata values
    ) external nonReentrant {
        uint256 length = recipients.length;

        require(length == values.length, "Length mismatch");
        require(length > 0, "Empty recipients");
        require(length <= MAX_BATCH_SIZE, "Batch too large");

        uint256 total;

        for (uint256 i; i < length; ) {
            address recipient = recipients[i];
            uint256 amount = values[i];

            require(recipient != address(0), "Zero address");

            total += amount;

            tokenClaims[token][recipient] += amount;

            emit TokenClaimCreated(
                msg.sender,
                address(token),
                recipient,
                amount
            );

            unchecked {
                ++i;
            }
        }

        token.safeTransferFrom(msg.sender, address(this), total);
    }

    // =============================================================
    //                         CLAIM
    // =============================================================

    function claimEther() external nonReentrant {
        uint256 amount = ethClaims[msg.sender];

        require(amount > 0, "No ETH claim available");

        ethClaims[msg.sender] = 0;

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "ETH claim failed");

        emit EtherClaimed(msg.sender, amount);
    }

    function claimToken(IERC20 token) external nonReentrant {
        uint256 amount = tokenClaims[token][msg.sender];

        require(amount > 0, "No token claim available");

        tokenClaims[token][msg.sender] = 0;

        token.safeTransfer(msg.sender, amount);

        emit TokenClaimed(msg.sender, address(token), amount);
    }

    // =============================================================
    //                        VIEW HELPERS
    // =============================================================

    function getTokenClaim(
        IERC20 token,
        address user
    ) external view returns (uint256) {
        return tokenClaims[token][user];
    }

    receive() external payable {}
}

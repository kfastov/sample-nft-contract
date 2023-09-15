// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "contracts/ERC721A.sol";

contract COolContract is ERC721A, Ownable, ReentrancyGuard {
    using Address for address;
    using Strings for uint;

    string public baseTokenURI =
        "ipfs://bafybeicisxqq4rx7ldiwrerqtafrvat5bucrvwshb6l7iotdhhbdsp765a";
    uint256 public maxSupply = 1000;
    uint256 public MAX_MINTS_PER_TX = 100;
    uint256 public PUBLIC_SALE_PRICE = 0.00777 ether;
    uint256 public NUM_FREE_MINTS = 0;
    uint256 public MAX_FREE_PER_WALLET = 3;
    uint256 public freeNFTAlreadyMinted = 0;
    bool public isPublicSaleActive = true;

    constructor() ERC721A("CoolContract", "CCNT") {}

    function calculateMintingPrice(
        uint256 quantity
    ) public view returns (uint256) {
        if (quantity == 10) {
            return 0.0005 ether;
        } else if (quantity == 100) {
            return 0.0045 ether;
        } else {
            return PUBLIC_SALE_PRICE * quantity;
        }
    }

    function mint(uint256 numberOfTokens) external payable {
        require(isPublicSaleActive, "Public sale is not open");
        require(totalSupply() + numberOfTokens <= maxSupply + 1, "No more");

        uint256 totalPrice = calculateMintingPrice(numberOfTokens);

        if (freeNFTAlreadyMinted + numberOfTokens > NUM_FREE_MINTS) {
            require(totalPrice <= msg.value, "Incorrect ETH value sent");
        } else {
            if (balanceOf(msg.sender) + numberOfTokens > MAX_FREE_PER_WALLET) {
                require(totalPrice <= msg.value, "Incorrect ETH value sent");
                require(
                    numberOfTokens <= MAX_MINTS_PER_TX,
                    "Max mints per transaction exceeded"
                );
            } else {
                require(
                    numberOfTokens <= MAX_FREE_PER_WALLET,
                    "Max mints per transaction exceeded"
                );
                freeNFTAlreadyMinted += numberOfTokens;
            }
        }
        _safeMint(msg.sender, numberOfTokens);
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function treasuryMint(uint quantity) public onlyOwner {
        require(quantity > 0, "Invalid mint amount");
        require(
            totalSupply() + quantity <= maxSupply,
            "Maximum supply exceeded"
        );
        _safeMint(msg.sender, quantity);
    }

    function withdraw() public onlyOwner nonReentrant {
        Address.sendValue(payable(msg.sender), address(this).balance);
    }

    function tokenURI(
        uint _tokenId
    ) public view virtual override returns (string memory) {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return
            string(
                abi.encodePacked(
                    baseTokenURI,
                    "/",
                    _tokenId.toString(),
                    ".json"
                )
            );
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setIsPublicSaleActive(
        bool _isPublicSaleActive
    ) external onlyOwner {
        isPublicSaleActive = _isPublicSaleActive;
    }

    function setNumFreeMints(uint256 _numfreemints) external onlyOwner {
        NUM_FREE_MINTS = _numfreemints;
    }

    function setmaxSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    function setSalePrice(uint256 _price) external onlyOwner {
        PUBLIC_SALE_PRICE = _price;
    }

    function setMaxLimitPerTransaction(uint256 _limit) external onlyOwner {
        MAX_MINTS_PER_TX = _limit;
    }

    function setFreeLimitPerWallet(uint256 _limit) external onlyOwner {
        MAX_FREE_PER_WALLET = _limit;
    }
}

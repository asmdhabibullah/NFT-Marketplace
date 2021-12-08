// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract NftMarket is ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _itemIds;
    Counters.Counter private _soldedItemsId;

    address payable private owner;
    uint256 private listingPrice = 0.0025 ether;

    constructor() {
        owner = payable(msg.sender);
    }

    struct MarketItem {
        uint256 itemId;
        address nftAddress;
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price;
        bool sold;
    }

    mapping(uint256 => MarketItem) private idToMarketItem;

    event MarketItemCreated(
        uint256 itemId,
        address nftAddress,
        uint256 tokenId,
        address payable seller,
        address payable owner,
        uint256 price,
        bool sold
    );

    function getListingPrice() public view returns (uint256) {
        return listingPrice;
    }

    function createItem(
        address nftContract,
        uint256 tokenId,
        uint256 price
    ) public payable nonReentrant {
        require(price > listingPrice, "Price must be equal to listing price");
        _itemIds.increment();
        uint256 newItemId = _itemIds.current();

        // MarketItem memory newMarketITEM = MarketItem({});

        // idToMarketItem.push(newMarketITEM);

        // idToMarketItem[itemId] = MarketItem(
        //     itemId,
        //     nftContract,
        //     tokenId,
        //     payable(msg.sender),
        //     payable(address(0)),
        //     price,
        //     false
        // );

        idToMarketItem[newItemId] = MarketItem({
            itemId: newItemId,
            nftAddress: nftContract,
            tokenId: tokenId,
            seller: payable(msg.sender),
            owner: payable(address(0)),
            price: price,
            sold: false
        });

        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);

        emit MarketItemCreated({
            itemId: newItemId,
            nftAddress: nftContract,
            tokenId: tokenId,
            seller: payable(msg.sender),
            owner: payable(address(0)),
            price: price,
            sold: false
        });
    }

    function sellItem(address nftContract, uint256 itemId)
        public
        payable
        nonReentrant
    {
        uint256 price = idToMarketItem[itemId].price;
        uint256 tokenId = idToMarketItem[itemId].tokenId;
        require(
            msg.value == price,
            "Please confirm your purches with asking price."
        );

        idToMarketItem[itemId].seller.transfer(msg.value);
        IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);
        idToMarketItem[itemId].sold = true;
        idToMarketItem[itemId].owner = payable(msg.sender);
        _soldedItemsId.increment();
        payable(owner).transfer(listingPrice);
    }
}

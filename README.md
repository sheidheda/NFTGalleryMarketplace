# NFT Gallery Marketplace

## Overview
NFT Gallery Marketplace is a decentralized application that enables users to mint, list, buy, and transfer NFTs in a secure and efficient manner. The contract includes input validation and error handling to ensure smooth interactions within the marketplace.

## Features
- **Minting NFTs**: Users can create unique NFTs with metadata such as name, description, and properties.
- **Listing NFTs**: NFT owners can list their tokens for sale at a specified price.
- **Buying NFTs**: Buyers can purchase listed NFTs by transferring the required amount.
- **Cancelling Listings**: Sellers can cancel their NFT listings at any time.
- **Transferring NFTs**: Owners can transfer NFTs to other users.
- **Querying NFTs**: Read-only functions allow users to fetch token ownership, metadata, and listing information.

## Smart Contract Functions

### Public Functions
- `mint(metadata-uri, name, description, properties) -> (ok token-id | err code)`  
  Creates a new NFT and stores its metadata.
- `list-token(token-id, price) -> (ok true | err code)`  
  Lists an NFT for sale at the specified price.
- `cancel-listing(token-id) -> (ok true | err code)`  
  Cancels an active NFT listing.
- `buy-token(token-id) -> (ok true | err code)`  
  Allows a buyer to purchase a listed NFT.
- `transfer-token(token-id, recipient) -> (ok true | err code)`  
  Transfers an NFT to another user.

### Read-Only Functions
- `get-token-owner(token-id) -> principal | err`  
  Returns the owner of an NFT.
- `get-listing(token-id) -> listing-data | none`  
  Retrieves the details of a listed NFT.
- `get-token-metadata(token-id) -> metadata | none`  
  Returns the metadata of an NFT.

## Error Handling
The contract defines several error codes for input validation and access control:
- `ERR-NOT-AUTHORIZED (u100)`: Unauthorized access attempt.
- `ERR-NFT-EXISTS (u101)`: Token already exists.
- `ERR-INVALID-PRICE (u102)`: Invalid price input.
- `ERR-NOT-OWNER (u103)`: Action attempted by a non-owner.
- `ERR-NOT-LISTED (u104)`: Token is not listed for sale.
- `ERR-INSUFFICIENT-FUNDS (u105)`: Buyer has insufficient funds.
- `ERR-INVALID-URI (u106)`: Invalid metadata URI.
- `ERR-INVALID-NAME (u107)`: Invalid token name.
- `ERR-INVALID-DESCRIPTION (u108)`: Invalid token description.
- `ERR-INVALID-PROPERTIES (u109)`: Invalid token properties.
- `ERR-INVALID-TOKEN-ID (u110)`: Token ID does not exist.
- `ERR-INVALID-RECIPIENT (u111)`: Transfer recipient is invalid.

## Installation & Deployment
1. Deploy the smart contract using Clarity on the Stacks blockchain.
2. Ensure all required permissions are granted for users to interact with the contract.

## Contribution
Contributions are welcome! Please submit a pull request with detailed changes.

## License
This project is open-source and available under the MIT License.


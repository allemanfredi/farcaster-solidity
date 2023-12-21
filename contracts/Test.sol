// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.9;


import {
  MessageDataCodec,
  MessageData,
  MessageType,
  ReactionType,
  CastId
} from './protobufs/message.proto.sol';

import {
  Blake3
} from './libraries/Blake3.sol';

import {
  Ed25519
} from './libraries/Ed25519.sol';

contract Test {
  event MessageCastAddVerified(uint64 fid, string text, uint64[] mentions);
  event MessageReactionAddVerified(uint64 fid, ReactionType reaction_type, uint64 target_fid, bytes target_hash);

  function _verifyMessage(
    bytes32 public_key,
    bytes32 signature_r,
    bytes32 signature_s,
    bytes memory message,
    MessageType message_type
  ) internal pure returns(MessageData memory) {
    // Calculate Blake3 hash of FC message (first 20 bytes)
    bytes memory message_hash = Blake3.hash(message, 20);

    // Verify signature
    bool valid = Ed25519.verify(
      public_key,
      signature_r,
      signature_s,
      message_hash
    );

    require(valid, 'Invalid signature');

    (
      bool success,
      ,
      MessageData memory message_data
    ) = MessageDataCodec.decode(0, message, uint64(message.length));

    require(success, 'Failed to decode message');
    require(message_data.type_ == message_type, 'Invalid message type');

    return message_data;
  }

  function verifyCastAddMessage(
    bytes32 public_key,
    bytes32 signature_r,
    bytes32 signature_s,
    bytes memory message
  ) external {
    MessageData memory message_data = _verifyMessage(
      public_key,
      signature_r,
      signature_s,
      message,
      MessageType.MESSAGE_TYPE_CAST_ADD
    );

    emit MessageCastAddVerified(
      message_data.fid,
      message_data.cast_add_body.text,
      message_data.cast_add_body.mentions
    );
  }

  function verifyReactionAddMessage(
    bytes32 public_key,
    bytes32 signature_r,
    bytes32 signature_s,
    bytes memory message
  ) external {
    MessageData memory message_data = _verifyMessage(
      public_key,
      signature_r,
      signature_s,
      message,
      MessageType.MESSAGE_TYPE_REACTION_ADD
    );

    emit MessageReactionAddVerified(
      message_data.fid,
      message_data.reaction_body.type_,
      message_data.reaction_body.target_cast_id.fid,
      message_data.reaction_body.target_cast_id.hash_
    );
  }
}
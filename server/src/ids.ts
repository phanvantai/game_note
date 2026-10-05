import { randomInt } from "node:crypto";

const ALPHABET = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";

/** 20-char random id, the same shape as Firestore auto ids. */
export function newId(): string {
  let id = "";
  for (let i = 0; i < 20; i++) id += ALPHABET[randomInt(ALPHABET.length)];
  return id;
}

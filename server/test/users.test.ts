import { describe, expect, it } from "vitest";
import { call, ok, seedGroup, seedUser, useTestApp } from "./helpers.js";

const ctx = useTestApp();

describe("auth", () => {
  it("rejects missing and invalid tokens", async () => {
    expect((await call(ctx, null, "GET", "/v1/me")).status).toBe(401);
    const res = await ctx.app.inject({ method: "GET", url: "/v1/me", headers: { authorization: "Bearer nope" } });
    expect(res.statusCode).toBe(401);
    expect(res.json()).toMatchObject({ error: "unauthenticated" });
  });

  it("health is public", async () => {
    expect((await ctx.app.inject({ method: "GET", url: "/health" })).json()).toEqual({ ok: true });
  });
});

describe("me", () => {
  it("bootstrap creates once, then returns the existing row unchanged", async () => {
    const first = await ok(ctx, "u1", "POST", "/v1/me/bootstrap", { displayName: "Tai", photoUrl: "http://x/p.png" });
    expect(first).toEqual({
      id: "u1", displayName: "Tai", phoneNumber: null, email: "u1@test.dev", photoUrl: "http://x/p.png",
      role: "user", isPlaceholder: false, deleted: false, deletedAt: null,
    });
    const again = await ok(ctx, "u1", "POST", "/v1/me/bootstrap", { displayName: "Other" });
    expect(again.displayName).toBe("Tai");
  });

  it("GET /v1/me 404s before bootstrap", async () => {
    expect((await call(ctx, "ghost", "GET", "/v1/me")).status).toBe(404);
  });

  it("PATCH ignores empty strings", async () => {
    await seedUser(ctx, "u1", "Tai");
    const user = await ok(ctx, "u1", "PATCH", "/v1/me", { displayName: "", phoneNumber: "0909" });
    expect(user).toMatchObject({ displayName: "Tai", phoneNumber: "0909" });
  });

  it("DELETE soft-deletes and clears contact info", async () => {
    await seedUser(ctx, "u1");
    expect((await call(ctx, "u1", "DELETE", "/v1/me")).status).toBe(204);
    const user = await ok(ctx, "u2", "GET", "/v1/users/u1");
    expect(user).toMatchObject({ deleted: true, email: null, phoneNumber: null });
    expect(user.deletedAt).toMatch(/Z$/);
  });
});

describe("users", () => {
  it("batch returns known ids only", async () => {
    await seedUser(ctx, "a");
    await seedUser(ctx, "b");
    const { users } = await ok(ctx, "a", "POST", "/v1/users/batch", { ids: ["a", "b", "zzz", "a"] });
    expect(users.map((u: any) => u.id).sort()).toEqual(["a", "b"]);
  });

  it("search matches name/email/phone prefixes case-insensitively", async () => {
    await seedUser(ctx, "a", "Tai Phan");
    await seedUser(ctx, "b", "Tam");
    await seedUser(ctx, "c", "Long");
    expect((await ok(ctx, "a", "GET", "/v1/users/search?q=ta")).map((u: any) => u.id)).toEqual(["a", "b"]);
    expect((await ok(ctx, "a", "GET", "/v1/users/search?q=c%40test")).map((u: any) => u.id)).toEqual(["c"]);
    expect(await ok(ctx, "a", "GET", "/v1/users/search?q=%25")).toEqual([]);
  });

  it("search within a group returns active members, members only", async () => {
    for (const u of ["owner", "m1", "m2", "out"]) await seedUser(ctx, u, `T-${u}`);
    const g = await seedGroup(ctx, "owner", ["m1", "m2"]);
    await ok(ctx, "owner", "PUT", `/v1/groups/${g}/members/m2/deactivation`, { deactivated: true });
    const found = await ok(ctx, "m1", "GET", `/v1/users/search?q=t&groupId=${g}`);
    expect(found.map((u: any) => u.id).sort()).toEqual(["m1", "owner"]);
    expect((await call(ctx, "out", "GET", `/v1/users/search?q=t&groupId=${g}`)).status).toBe(403);
    expect((await call(ctx, "out", "GET", `/v1/users/search?q=t&groupId=nope`)).status).toBe(404);
  });

  it("creates placeholder users", async () => {
    await seedUser(ctx, "a");
    const p = await ok(ctx, "a", "POST", "/v1/users/placeholders", { displayName: "  Bob " });
    expect(p.id).toMatch(/^placeholder_[A-Za-z0-9]{20}$/);
    expect(p).toMatchObject({ displayName: "Bob", isPlaceholder: true });
    expect((await call(ctx, "a", "POST", "/v1/users/placeholders", { displayName: "" })).status).toBe(400);
  });

  it("GET unknown user 404s", async () => {
    expect((await call(ctx, "a", "GET", "/v1/users/nobody")).body).toMatchObject({ error: "not_found" });
  });
});

describe("avatars", () => {
  const upload = (uid: string, type = "image/png") => {
    const boundary = "----gn";
    const payload = Buffer.concat([
      Buffer.from(`--${boundary}\r\nContent-Disposition: form-data; name="file"; filename="a.png"\r\nContent-Type: ${type}\r\n\r\n`),
      Buffer.from([0x89, 0x50, 0x4e, 0x47]),
      Buffer.from(`\r\n--${boundary}--\r\n`),
    ]);
    return ctx.app.inject({
      method: "PUT",
      url: "/v1/me/avatar",
      headers: { authorization: `Bearer uid:${uid}`, "content-type": `multipart/form-data; boundary=${boundary}` },
      payload,
    });
  };

  it("uploads, serves, replaces and deletes an avatar", async () => {
    await seedUser(ctx, "u1");
    const first = (await upload("u1")).json();
    expect(first.photoUrl).toMatch(/^http:\/\/api\.test\/avatars\/u1-\d+\.png$/);
    const path = new URL(first.photoUrl).pathname;
    const served = await ctx.app.inject({ method: "GET", url: path });
    expect(served.statusCode).toBe(200);
    expect(served.headers["content-type"]).toBe("image/png");
    expect(served.rawPayload).toEqual(Buffer.from([0x89, 0x50, 0x4e, 0x47]));

    await new Promise((r) => setTimeout(r, 2));
    const second = (await upload("u1")).json();
    expect(second.photoUrl).not.toBe(first.photoUrl);
    expect((await ctx.app.inject({ method: "GET", url: path })).statusCode).toBe(404);

    const cleared = await ok(ctx, "u1", "DELETE", "/v1/me/avatar");
    expect(cleared.photoUrl).toBeNull();
    expect((await ctx.app.inject({ method: "GET", url: new URL(second.photoUrl).pathname })).statusCode).toBe(404);
  });

  it("rejects non-images and path tricks", async () => {
    await seedUser(ctx, "u1");
    expect((await upload("u1", "text/plain")).statusCode).toBe(400);
    expect((await ctx.app.inject({ method: "GET", url: "/avatars/..%2Fsecret.png" })).statusCode).toBe(404);
  });
});

import { characters, getCharacterByHandle } from "../characters";

describe("characters", () => {
  describe("characters array", () => {
    it("exports at least 2 characters", () => {
      expect(characters.length).toBeGreaterThanOrEqual(2);
    });

    it("every character has the required fields", () => {
      for (const char of characters) {
        expect(typeof char.handle).toBe("string");
        expect(char.handle.length).toBeGreaterThan(0);
        expect(typeof char.name).toBe("string");
        expect(char.name.length).toBeGreaterThan(0);
        expect(typeof char.description).toBe("string");
        expect(char.description.length).toBeGreaterThan(0);
        expect(typeof char.personality).toBe("string");
        expect(char.personality.length).toBeGreaterThan(0);
        expect(Array.isArray(char.interests)).toBe(true);
        expect(char.interests.length).toBeGreaterThan(0);
        expect(typeof char.initialPlan).toBe("string");
        expect(char.initialPlan.length).toBeGreaterThan(0);
      }
    });

    it("all handles are unique", () => {
      const handles = characters.map((c) => c.handle);
      const unique = new Set(handles);
      expect(unique.size).toBe(handles.length);
    });

    it("includes expected AI Town residents", () => {
      const handles = characters.map((c) => c.handle);
      expect(handles).toContain("pixel");
      expect(handles).toContain("sage");
      expect(handles).toContain("nova");
      expect(handles).toContain("reed");
      expect(handles).toContain("zara");
    });
  });

  describe("getCharacterByHandle", () => {
    it("returns the matching character", () => {
      const char = getCharacterByHandle("pixel");
      expect(char).toBeDefined();
      expect(char!.name).toBe("Pixel");
    });

    it("returns undefined for an unknown handle", () => {
      expect(getCharacterByHandle("nobody")).toBeUndefined();
    });

    it("is case-sensitive", () => {
      expect(getCharacterByHandle("Pixel")).toBeUndefined();
    });
  });
});

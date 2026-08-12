(async () => {
  /* Extract an image FILL's original bytes from a Figma node, as base64.
   *
   * Why this exists: `figma-cli export node` rasterises the node as it appears on
   * canvas. For a hero that means the composite — every scrim, overlay, and vignette
   * baked in, at whatever --scale you pass. Measured on one 1440x900 hero: a 4.07MB
   * PNG re-render, versus the 766KB original JPEG the fill actually holds. The
   * re-render is both larger and wrong, because the overlays must stay live in CSS
   * so they can respond to theme and viewport.
   *
   * `getImageByHash(hash).getBytesAsync()` returns the source asset instead —
   * byte-identical to what was placed in Figma.
   *
   * NOTE: every comment here lives INSIDE the IIFE deliberately. `figma-cli run`
   * silently returns nothing — no output, no error, exit 0 — when a file carries
   * leading `//` comments before the opening `(async () => {`.
   *
   * Usage: substitute __NODE_ID__, then
   *   figma-cli run extract-image.js > out.b64 && base64 -d out.b64 > asset.jpg
   * Verify the byte count against the `bytes` field this prints in metadata mode. */
  const NODE_ID = "__NODE_ID__";
  const node = await figma.getNodeByIdAsync(NODE_ID);
  if (!node) return "ERROR: node " + NODE_ID + " not found";

  const paints = Array.isArray(node.fills) ? node.fills : [];
  const images = paints.filter((p) => p.type === "IMAGE" && p.visible !== false);
  if (!images.length) {
    /* A node can also carry an image on a STROKE, or hold it on a child. Say which,
     * rather than reporting a bare "no image" that reads as "wrong node id". */
    const kids = node.children ? node.children.length : 0;
    return "ERROR: no visible IMAGE fill on " + node.type + ' "' + node.name + '"' +
      (kids ? " — it has " + kids + " child(ren); the fill may live on one of them" : "");
  }
  if (images.length > 1) {
    return "ERROR: " + images.length + " image fills on this node — ambiguous. " +
      "Stacked fills are a composite; extract each by index deliberately.";
  }

  const paint = images[0];
  const image = figma.getImageByHash(paint.imageHash);
  if (!image) return "ERROR: fill references hash " + paint.imageHash + " but no image resolved";

  const bytes = await image.getBytesAsync();
  const size = await image.getSizeAsync();

  /* Sniff the real container from magic bytes. The fill carries no format field, and
   * naming a JPEG .png produces a file that renders fine in a browser and breaks
   * every image pipeline downstream. */
  let ext = "bin";
  if (bytes[0] === 0xff && bytes[1] === 0xd8) ext = "jpg";
  else if (bytes[0] === 0x89 && bytes[1] === 0x50) ext = "png";
  else if (bytes[0] === 0x47 && bytes[1] === 0x49) ext = "gif";
  else if (bytes[0] === 0x52 && bytes[1] === 0x49) ext = "webp";

  /* Metadata mode: print the facts needed to write correct CSS and to verify the
   * decoded file, without moving a megabyte through stdout. Substitute the __META__
   * placeholder with `true` (metadata) or `false` (base64 payload). */
  if (__META__) {
    return JSON.stringify({
      hash: paint.imageHash,
      scaleMode: paint.scaleMode,
      naturalSize: size,
      bytes: bytes.length,
      format: ext,
      imageTransform: paint.imageTransform || null,
      nodeSize: { width: Math.round(node.width), height: Math.round(node.height) },
      cssObjectFit: paint.scaleMode === "FILL" ? "cover"
        : paint.scaleMode === "FIT" ? "contain"
        : paint.scaleMode === "CROP" ? "cover (with imageTransform — verify the offset)"
        : "repeat via background-image",
    }, null, 2);
  }

  let out = "";
  const CHUNK = 0x8000; /* String.fromCharCode.apply overflows the stack on a large array */
  for (let i = 0; i < bytes.length; i += CHUNK) {
    out += String.fromCharCode.apply(null, bytes.subarray(i, i + CHUNK));
  }
  return btoa(out);
})();

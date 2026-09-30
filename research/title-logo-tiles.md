# Title logo tile graphics

The Japanese origin release stores its 96-tile, 128×48 2bpp title logo at `0x10419`. The English fallback release stores a distinct 115-tile title-logo sheet at `0xf46fb`; its final logical row is partially populated, so the shared renderer pads only the absent display cells and does not invent source tiles.

The ranges are identified against `PokemonLogoJapanGraphics` (`gfx/title/pokemon_logo_japan.2bpp`) and `PokemonLogoGraphics` (`gfx/title/pokemon_logo.2bpp`) in `pret/pokeyellow`. The English tile-sheet PNG intentionally preserves ROM tile order.

The English on-screen composition is also reconstructed. Its 16×7 `TitleScreenPokemonLogoTilemap` is at `0xf45f9`; tile ID `0xf4` is the blank background. The one `0xfd` cell refers to the separately loaded three-tile `PokemonLogoCornerGraphics` range at `0xf4e2b`. Combining those ranges produces `pokemon-logo-composed-en.png`, visually verified as the complete Pokémon Yellow Version logo.

The German release uses the same tilemap and corner offsets with a localized 115-tile sheet at `0xf46fb`, producing `POKÉMON GELBE EDITION`. The French layout is shifted by twelve bytes: tilemap `0xf4605`, sheet `0xf4707`, and corner tiles `0xf4e37`; its composed result reads `POKÉMON VERSION JAUNE`. The distinct sheet hashes prove these are localized assets rather than renamed copies of the English result.

All PNGs are derived from locally verified retail ROMs. The reports and manifest retain full-ROM identity, offset, length, source hash, layout, and output hash without publishing ROM bytes.

# Title logo tile graphics

The Japanese origin release stores its 96-tile, 128×48 2bpp title logo at `0x10419`. The English fallback release stores a distinct 115-tile title-logo sheet at `0xf46fb`; its final logical row is partially populated, so the shared renderer pads only the absent display cells and does not invent source tiles.

The ranges are identified against `PokemonLogoJapanGraphics` (`gfx/title/pokemon_logo_japan.2bpp`) and `PokemonLogoGraphics` (`gfx/title/pokemon_logo.2bpp`) in `pret/pokeyellow`. The English PNG intentionally preserves ROM tile order. Its on-screen arrangement is controlled separately by `TitleScreenPokemonLogoTilemap`; a later reconstruction unit will combine the verified tile sheet and tilemap into the composed screen asset.

Both PNGs are derived from locally verified retail ROMs. The reports and manifest retain full-ROM identity, offset, length, source hash, layout, and output hash without publishing ROM bytes.

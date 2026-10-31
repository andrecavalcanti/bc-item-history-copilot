## Module: Negative inventory (problemType: NegativeInventory)

**What is wrong:** when stock is shipped or consumed before it is received, the outbound item ledger
entry cannot be applied to stock. It stays open with a negative remaining quantity until a receipt
covers it. Open negative entries mean inventory went below zero, and costs on those entries are
provisional until they are covered.

**Tools:**
- List_NegativeInventoryLines_QRY58002 (detection): item/location combinations with open outbound
  entries, with openNegativeQuantity (always negative) and entryCount.

**Investigation steps:**
1. Read the item entries for the item and location with isOpen = true. The open negative ones are the
   outbound entries that were not covered; note their posting dates and documents.
2. Read the positive entries for the same item around those dates, at the same and at other locations.
   Check whether a receipt was posted later than the shipment, or at another location.

**Typical root causes:**
- A shipment or consumption was posted before the purchase receipt or output that should have covered it.
- The receipt was posted at a different location than the shipment.
- A positive adjustment or transfer was never posted after a physical count or move.

**Example proposed fix:** "Post the pending purchase receipt for order 106014 at location WEST, or
transfer 5 units from MAIN to WEST. Then run Adjust Cost - Item Entries so costs are corrected."

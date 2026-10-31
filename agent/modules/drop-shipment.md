## Module: Drop shipment (problemType: DropShipment)

**What is wrong:** in a correct drop shipment, the purchase receipt and the sales shipment are posted
together, so drop-ship item ledger entries for an item and location always net to zero. A non-zero
net quantity means something went wrong.

**Tools:**
- List_DropShipImbalances_QRY58001 (detection): item/location combinations whose drop-ship entries
  do not net to zero, with netQuantity.
- List_DropShipSalesLines_PAG58005: open drop-ship sales order lines and their linked purchase order line.
- List_DropShipPurchaseLines_PAG58006: open drop-ship purchase order lines and their linked sales order line.

**Investigation steps:**
1. Read the item entries for the item and location with dropShipment = true. Group them by order no.
   and find which order's receipts and shipments do not match.
2. Read the related sales and purchase lines. Check whether each sales line points to the purchase
   line that points back to it, and compare quantity shipped with quantity received.

**Typical root causes:**
- A sales line was linked to a purchase line that was not a drop shipment, or the link was changed
  after posting (for example through a configuration package or a manual edit).
- Goods were received to the warehouse on a drop-ship purchase line instead of being shipped to the customer.
- A drop-ship line was partly posted and then quantities were changed on one side only.
- A correction (return, credit memo, item journal) was posted on one side only.

**Example proposed fix:** "Confirm with the warehouse whether the 4 units are physically in stock at EAST.
If not, post a corrective item journal of -4 at EAST; if they are, reclassify them as normal stock."

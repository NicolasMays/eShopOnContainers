using System.Collections.Generic;

namespace Microsoft.eShopOnContainers.Web.Shopping.HttpAggregator.Models
{

    public class BasketData
    {
        public string BuyerId { get; set; }

        public List<BasketDataItem> Items { get; set; } = new List<BasketDataItem>();
        public Coupon Coupon { get; set; } = new Coupon {Discount = 0};
        public BasketData()
        {
        }

        public BasketData(string buyerId)
        {
            BuyerId = buyerId;
        }
    }

}

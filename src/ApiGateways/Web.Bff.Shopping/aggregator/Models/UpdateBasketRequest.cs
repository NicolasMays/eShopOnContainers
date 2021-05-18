using System.Collections.Generic;

namespace Microsoft.eShopOnContainers.Web.Shopping.HttpAggregator.Models
{

    public class UpdateBasketRequest
    {
        public string BuyerId { get; set; }
        public Coupon Coupon { get; set; } = new Coupon();
        public IEnumerable<UpdateBasketRequestItemData> Items { get; set; }
    }

}

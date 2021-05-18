using System.Collections.Generic;

namespace Microsoft.eShopOnContainers.Web.Shopping.HttpAggregator.Models
{

    public class Coupon
    {
        public string CouponCode { get; set; }
        public string ExpirationDate { get; set; }
        public decimal Discount { get; set; }
    }

}

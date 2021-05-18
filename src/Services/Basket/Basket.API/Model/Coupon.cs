using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace Microsoft.eShopOnContainers.Services.Basket.API.Model
{
    public class Coupon
    {
        public string CouponCode { get; set; }
        public string ExpirationDate { get; set; }
        public decimal Discount { get; set; }
    }
}

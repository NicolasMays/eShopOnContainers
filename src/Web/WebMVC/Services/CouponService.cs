using Microsoft.AspNetCore.Mvc.Rendering;
using Microsoft.eShopOnContainers.WebMVC.ViewModels;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Threading.Tasks;
using WebMVC.Infrastructure;
using WebMVC.Services.ModelDTOs;

namespace Microsoft.eShopOnContainers.WebMVC.Services
{
    public class CouponService : ICouponService
    {
        private readonly IOptions<AppSettings> _settings;
        private readonly HttpClient _apiClient;
        private readonly ILogger<CouponService> _logger;

        public CouponService(HttpClient httpClient, IOptions<AppSettings> settings, ILogger<CouponService> logger)
        {
            _apiClient = httpClient;
            _settings = settings;
            _logger = logger;
        }

        public async Task<Basket> Apply(Basket basket, string couponCode)
        {
            // This should reach out to a coupon service to get the coupon details from the coupon code
            // ***
            Coupon coupon = couponCode == "SH360" ? new Coupon
            {
                CouponCode = couponCode,
                ExpirationDate = "04/19/2025",
                Discount = (decimal)0.1
            } : new Coupon() { Discount = 0 };
            // ***
            // ***
            // ***
            List<BasketItem> Items = new List<BasketItem>();
            foreach (BasketItem Item in basket.Items.Select(item => item).ToList())
            {
                Items.Add(
                new BasketItem
                {
                    Id = Item.Id,
                    ProductId = Item.ProductId,
                    ProductName = Item.ProductName,
                    UnitPrice = Item.isDiscounted == true ? Item.UnitPrice : Item.UnitPrice * (1 - coupon.Discount),
                    OldUnitPrice = Item.isDiscounted == true ? Item.OldUnitPrice : Item.UnitPrice,
                    Quantity = Item.Quantity,
                    PictureUrl = Item.PictureUrl,
                    isDiscounted = coupon.Discount > 0 ? true : Item.isDiscounted,
                });
            }

            Basket basketUpdate = new Basket
            {
                BuyerId = basket.BuyerId,
                Items = Items,
                Coupon = coupon
            };
            return basketUpdate;
        }
    }
}

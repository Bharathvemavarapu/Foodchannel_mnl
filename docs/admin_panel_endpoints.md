# FoodChannel MNL Admin Panel & Data Endpoints Documentation

This document provides a comprehensive overview of the administrative interface and data schema endpoints for the **FoodChannel MNL** project.

---

## 1. Architectural Overview

The application is built using **Flutter (Dart)**. It communicates with backend services using direct HTTP REST requests to Firebase and Cloudinary, avoiding heavy SDK wrappers to maintain light footprint execution.

### Backend Stack
*   **Database & Auth**: [Firebase Realtime Database REST API](https://firebase.google.com/docs/reference/rest/database) + Firebase Authentication.
*   **Image Storage**: Cloudinary REST API.
*   **Geocoding**: Mapbox Places API.

---

## 2. Admin Dashboard Panel (UI Layout)

The main dashboard is defined in [admin_dashboard_view.dart](file:///c:/Users/allad/OneDrive/Desktop/projects/foodchannel_mnl/lib/views/admin/admin_dashboard_view.dart).
*   **Responsive Layout**: 
    *   **Desktop (width >= 1024px)**: Uses a persistent left-sidebar with menu group dividers.
    *   **Mobile/Tablet**: Uses a slide-out navigation `Drawer`.
*   **Active Views**: Toggled dynamically through state variables indexing 13 administrative tabs.

### Administrative Menu Tabs
The sidebar groups views into five sections:

#### Group A: OVERVIEW
1.  **Dashboard** ([dashboard_tab.dart](file:///c:/Users/allad/OneDrive/Desktop/projects/foodchannel_mnl/lib/views/admin/tabs/dashboard_tab.dart))
    *   *Purpose*: Provides analytical statistics (Total Revenue, Orders Count, Product Count, Support Tickets, Pending Actions).
    *   *Displays*: Order sales charts and a recent transaction grid.
2.  **Users** ([users_tab.dart](file:///c:/Users/allad/OneDrive/Desktop/projects/foodchannel_mnl/lib/views/admin/tabs/users_tab.dart))
    *   *Purpose*: Lists all registered profiles.
    *   *Controls*: Access toggle (IsActive) and user role changing.
3.  **Orders** ([orders_tab.dart](file:///c:/Users/allad/OneDrive/Desktop/projects/foodchannel_mnl/lib/views/admin/tabs/orders_tab.dart))
    *   *Purpose*: Displays orders grouped by status.
    *   *Controls*: Timeline status updates, order cancellations, and refund processing.
4.  **Payments** ([payments_tab.dart](file:///c:/Users/allad/OneDrive/Desktop/projects/foodchannel_mnl/lib/views/admin/tabs/payments_tab.dart))
    *   *Purpose*: Monitors financial transactions and configures payment gateways (Stripe, Razorpay, Cashfree, PhonePe).
5.  **Customer Support** ([support_tab.dart](file:///c:/Users/allad/OneDrive/Desktop/projects/foodchannel_mnl/lib/views/admin/tabs/support_tab.dart))
    *   *Purpose*: Displays support tickets sent by users. Allows replies and ticket closure.

#### Group B: CATALOG
6.  **Categories** ([categories_tab.dart](file:///c:/Users/allad/OneDrive/Desktop/projects/foodchannel_mnl/lib/views/admin/tabs/categories_tab.dart))
    *   *Purpose*: CRUD operations on main food/cookware categories.
7.  **Sub Categories** ([subcategories_tab.dart](file:///c:/Users/allad/OneDrive/Desktop/projects/foodchannel_mnl/lib/views/admin/tabs/subcategories_tab.dart))
    *   *Purpose*: CRUD operations on nested categories.
8.  **Products** ([products_tab.dart](file:///c:/Users/allad/OneDrive/Desktop/projects/foodchannel_mnl/lib/views/admin/tabs/products_tab.dart))
    *   *Purpose*: Extensive inventory management (pricing, discount prices, stock count, SKUs, brand description, features, trending toggles).

#### Group C: STORE CONFIG
9.  **App Settings** ([settings_tab.dart](file:///c:/Users/allad/OneDrive/Desktop/projects/foodchannel_mnl/lib/views/admin/tabs/settings_tab.dart))
    *   *Purpose*: Configures basic store configurations (Store name, logo image, brief descriptions, email/whatsapp/support phone numbers).
10. **Promotional Banners** ([banners_tab.dart](file:///c:/Users/allad/OneDrive/Desktop/projects/foodchannel_mnl/lib/views/admin/tabs/banners_tab.dart))
    *   *Purpose*: Add, update status, and delete promotional banner images.
11. **Hero Images** ([hero_tab.dart](file:///c:/Users/allad/OneDrive/Desktop/projects/foodchannel_mnl/lib/views/admin/tabs/hero_tab.dart))
    *   *Purpose*: Reorder slider hero cards on the client application homepage.
12. **Store Address** ([store_address_tab.dart](file:///c:/Users/allad/OneDrive/Desktop/projects/foodchannel_mnl/lib/views/admin/tabs/store_address_tab.dart))
    *   *Purpose*: Store address setting with lat/lng geolocation integration.

#### Group D: MARKETING
13. **Notifications** ([notifications_tab.dart](file:///c:/Users/allad/OneDrive/Desktop/projects/foodchannel_mnl/lib/views/admin/tabs/notifications_tab.dart))
    *   *Purpose*: Broadcast notifications to all users or select target user cohorts.

---

## 3. Database Schema & REST Endpoints

All data is stored in the Firebase Realtime Database. The REST API root URL is:
`https://foodchannelmnl-default-rtdb.firebaseio.com`

Authorized writing operations must append Firebase client tokens to the URL query string: `?auth=$token`.

### 3.1. Authentication Credentials & Access
The database token is retrieved dynamically:
*   **Method**: `DatabaseService._getToken()`
*   **Implementation**: `FirebaseAuth.instance.currentUser?.getIdToken()`

---

### 3.2. Data Schemes & Endpoint Methods

Here is the exact schema representation and REST endpoints matching [database_service.dart](file:///c:/Users/allad/OneDrive/Desktop/projects/foodchannel_mnl/lib/services/database_service.dart).

#### 3.2.1. Categories
*   **Fetch (GET)**: `/store/categories.json`
*   **Add (POST)**: `/store/categories.json?auth=$token`
*   **Update (PATCH)**: `/store/categories/$id.json?auth=$token`
*   **Delete (DELETE)**: `/store/categories/$id.json?auth=$token`

##### Model / Payload Structure:
```json
{
  "name": "String",
  "imageUrl": "String",
  "createdDate": "ISO8601 String"
}
```

---

#### 3.2.2. Subcategories
*   **Fetch (GET)**: `/store/subcategories.json`
*   **Add (POST)**: `/store/subcategories.json?auth=$token`
*   **Update (PATCH)**: `/store/subcategories/$id.json?auth=$token`
*   **Delete (DELETE)**: `/store/subcategories/$id.json?auth=$token`

##### Model / Payload Structure:
```json
{
  "categoryId": "String (Reference ID)",
  "name": "String",
  "imageUrl": "String",
  "createdDate": "ISO8601 String"
}
```

---

#### 3.2.3. Products
*   **Fetch (GET)**: `/store/products.json`
*   **Add (POST)**: `/store/products.json?auth=$token`
*   **Update (PUT)**: `/store/products/$id.json?auth=$token`
*   **Delete (DELETE)**: `/store/products/$id.json?auth=$token`

##### Model / Payload Structure:
```json
{
  "name": "String",
  "description": "String",
  "imageUrls": ["String"],
  "price": 0.0,
  "discountPrice": 0.0,
  "stock": 0,
  "brand": "String",
  "sku": "String",
  "categoryId": "String",
  "subCategoryId": "String",
  "isAvailable": true,
  "isFeatured": false,
  "isTrending": false,
  "createdDate": "ISO8601 String"
}
```

---

#### 3.2.4. App Settings
*   **Fetch (GET)**: `/store/settings.json`
*   **Save (PUT)**: `/store/settings.json?auth=$token`

##### Model / Payload Structure:
```json
{
  "name": "String",
  "logoUrl": "String",
  "description": "String",
  "contactNumber": "String",
  "email": "String",
  "whatsapp": "String"
}
```

---

#### 3.2.5. Promotional Banners
*   **Fetch (GET)**: `/store/banners.json`
*   **Add (POST)**: `/store/banners.json?auth=$token`
*   **Update (PATCH)**: `/store/banners/$id.json?auth=$token`
*   **Delete (DELETE)**: `/store/banners/$id.json?auth=$token`

##### Model / Payload Structure:
```json
{
  "imageUrl": "String",
  "isEnabled": true,
  "createdDate": "ISO8601 String"
}
```

---

#### 3.2.6. Hero Images
*   **Fetch (GET)**: `/store/heroImages.json`
*   **Save (PUT - Bulk Overwrite)**: `/store/heroImages.json?auth=$token`

##### Model / Payload Structure:
```json
{
  "hero_id_1": {
    "imageUrl": "String",
    "sortOrder": 0
  },
  "hero_id_2": {
    "imageUrl": "String",
    "sortOrder": 1
  }
}
```

---

#### 3.2.7. Store Address
*   **Fetch (GET)**: `/store/address.json`
*   **Save (PUT)**: `/store/address.json?auth=$token`

##### Model / Payload Structure:
```json
{
  "fullAddress": "String",
  "latitude": 0.0,
  "longitude": 0.0
}
```

---

#### 3.2.8. User Profiles
*   **Fetch All (GET)**: `/users.json?auth=$token`
*   **Update Details (PUT)**: `/users/$uid.json?auth=$token`
*   **Delete Profile (DELETE)**: `/users/$uid.json?auth=$token`

##### Model / Payload Structure:
```json
{
  "name": "String",
  "email": "String",
  "role": "String (e.g. 'user' or 'admin')",
  "phone": "String",
  "isActive": true,
  "createdDate": "ISO8601 String",
  "lastLogin": "ISO8601 String"
}
```

---

#### 3.2.9. Orders
*   **Fetch All (GET)**: `/orders.json?auth=$token`
*   **Add Order (PUT)**: `/orders/$id.json?auth=$token`
*   **Update Order Status (PATCH)**: `/orders/$id.json?auth=$token`

##### Model / Payload Structure:
```json
{
  "customerId": "String",
  "customerName": "String",
  "customerEmail": "String",
  "customerPhone": "String",
  "totalAmount": 0.0,
  "deliveryAddress": "String",
  "paymentMethod": "String",
  "paymentStatus": "String (e.g. 'Pending', 'Paid', 'Failed', 'Refunded')",
  "status": "String (e.g. 'Pending', 'Confirmed', 'Delivered', 'Cancelled')",
  "createdDate": "ISO8601 String",
  "items": [
    {
      "productId": "String",
      "name": "String",
      "quantity": 1,
      "price": 0.0
    }
  ],
  "timeline": [
    {
      "status": "String",
      "timestamp": "ISO8601 String",
      "notes": "String"
    }
  ]
}
```

---

#### 3.2.10. Payments Settings & Transactions
*   **Fetch Gateway Settings (GET)**: `/store/paymentsSettings.json?auth=$token`
*   **Save Settings (PUT)**: `/store/paymentsSettings.json?auth=$token`
*   **Fetch Transactions (GET)**: `/payments.json?auth=$token`
*   **Record Transaction (PUT)**: `/payments/$id.json?auth=$token`

##### Gateway Config Sub-Structure:
```json
{
  "isEnabled": false,
  "testApiKey": "String",
  "testApiSecret": "String",
  "liveApiKey": "String",
  "liveApiSecret": "String",
  "isLiveMode": false
}
```

##### Payment Settings Payload:
```json
{
  "razorpay": { ...GatewayConfig },
  "stripe": { ...GatewayConfig },
  "cashfree": { ...GatewayConfig },
  "phonepe": { ...GatewayConfig },
  "codEnabled": true,
  "minOrderAmountForOnline": 0.0
}
```

##### Transaction Payload:
```json
{
  "orderId": "String",
  "customerName": "String",
  "gateway": "String",
  "amount": 0.0,
  "status": "String (Success/Failed/Pending/Refunded)",
  "transactionId": "String",
  "timestamp": "ISO8601 String",
  "errorMessage": "String"
}
```

---

#### 3.2.11. Support Tickets
*   **Fetch All Tickets (GET)**: `/supportTickets.json?auth=$token`
*   **Create Ticket (PUT)**: `/supportTickets/$id.json?auth=$token`
*   **Add Reply / Update Status (PATCH)**: `/supportTickets/$id.json?auth=$token`

##### Model / Payload Structure:
```json
{
  "customerId": "String",
  "customerName": "String",
  "customerEmail": "String",
  "customerPhone": "String",
  "type": "String (e.g. 'Complaint', 'Return Request')",
  "subject": "String",
  "message": "String",
  "imageUrl": "String (Optional)",
  "status": "String (e.g. 'Open', 'In Progress', 'Resolved')",
  "createdDate": "ISO8601 String",
  "updatedDate": "ISO8601 String",
  "replies": [
    {
      "sender": "String ('Admin' or 'Customer')",
      "message": "String",
      "timestamp": "ISO8601 String"
    }
  ]
}
```

---

#### 3.2.12. Notifications
*   **Fetch Sent Notifications (GET)**: `/notifications.json?auth=$token`
*   **Schedule/Send Notification (PUT)**: `/notifications/$id.json?auth=$token`

##### Model / Payload Structure:
```json
{
  "title": "String",
  "body": "String",
  "type": "String ('All Users', 'Selected Users', 'Promotional')",
  "targetUserIds": ["String"],
  "scheduledTime": "ISO8601 String (Optional)",
  "createdDate": "ISO8601 String",
  "isSent": false
}
```

---

## 4. Media Storage (Cloudinary Upload)

All dynamic media content (e.g. product photos, promotional banners, category illustrations) is uploaded to Cloudinary:
*   **REST Endpoint**: `https://api.cloudinary.com/v1_1/dus8mvmah/image/upload`
*   **Method**: Multipart `POST`
*   **Parameters Required**:
    *   `api_key`: `954923814699169`
    *   `timestamp`: Current UNIX Timestamp
    *   `upload_preset`: `ml_default`
    *   `signature`: SHA1 Hex Digest of `timestamp=$timestamp&upload_preset=ml_default$apiSecret`
    *   `file`: Raw binary image file bytes.

---

## 5. Store Address Geocoding (Mapbox)

Address lookups inside [store_address_tab.dart](file:///c:/Users/allad/OneDrive/Desktop/projects/foodchannel_mnl/lib/views/admin/tabs/store_address_tab.dart) hit the Mapbox Geocoding endpoint:
*   **Endpoint**: `https://api.mapbox.com/geocoding/v5/mapbox.places/{query}.json`
*   **Method**: `GET`
*   **Query String parameters**:
    *   `access_token`: `pk.eyJ1IjoicGF2YW5rdW1hcnN3YW15IiwiYSI6ImNtNnc1c3ZpdTBkdGgyanM5b25rN2ZqcncifQ.Ls1e2W6rx3apoBsStWa5Ow`
    *   `limit`: `5`
